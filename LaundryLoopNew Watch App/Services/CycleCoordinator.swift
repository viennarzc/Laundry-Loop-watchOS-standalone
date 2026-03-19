import Combine
import Foundation
import SwiftData
import UserNotifications
import WidgetKit

@MainActor
final class CycleCoordinator: ObservableObject {
    @Published private(set) var snapshot: ActiveCycleSnapshot?
    @Published private(set) var settings: AppSettings
    @Published private(set) var recentPresets: [RecentPreset]
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let snapshotStore: SnapshotStoring
    private let settingsStore: SettingsStoring
    private let recentPresetStore: RecentPresetStoring
    private let notificationScheduler: NotificationScheduling
    private let haptics: HapticsPlaying

    init(
        snapshotStore: SnapshotStoring,
        settingsStore: SettingsStoring,
        recentPresetStore: RecentPresetStoring,
        notificationScheduler: NotificationScheduling,
        haptics: HapticsPlaying
    ) {
        self.snapshotStore = snapshotStore
        self.settingsStore = settingsStore
        self.recentPresetStore = recentPresetStore
        self.notificationScheduler = notificationScheduler
        self.haptics = haptics
        self.settings = (try? settingsStore.loadSettings()) ?? .default
        self.recentPresets = (try? recentPresetStore.loadRecentPresets()) ?? []
        if let stored = snapshotStore.load() {
            self.snapshot = CycleTimerEngine.normalize(stored)
        } else {
            self.snapshot = nil
        }
    }

    func refreshFromPersistence() async {
        settings = (try? settingsStore.loadSettings()) ?? .default
        recentPresets = (try? recentPresetStore.loadRecentPresets()) ?? []
        if let stored = snapshotStore.load() {
            let normalized = CycleTimerEngine.normalize(stored)
            snapshot = normalized
            snapshotStore.save(normalized)
            await notificationScheduler.scheduleNotifications(for: normalized, settings: settings)
        } else {
            snapshot = nil
            await notificationScheduler.cancelScheduledNotifications()
        }
        notificationStatus = await notificationScheduler.authorizationStatus()
        if snapshot?.status == .completed {
            playCompletionIfNeeded()
        }
    }

    func configureNotificationsOnLaunch() async {
        await notificationScheduler.registerCategories()
        notificationStatus = await notificationScheduler.authorizationStatus()
    }

    func startDefaultCycle(kind: CycleKind) async {
        let minutes = kind == .washer ? settings.defaultWasherMinutes : settings.defaultDryerMinutes
        await startCycle(kind: kind, minutes: minutes)
    }

    func startCycle(kind: CycleKind, minutes: Int) async {
        let normalizedMinutes = max(minutes, 1)
        let now = Date()
        let newSnapshot = CycleTimerEngine.start(kind: kind, minutes: normalizedMinutes, reminderLeadMinutes: settings.reminderLeadMinutes, now: now)
        snapshot = newSnapshot
        snapshotStore.save(newSnapshot)
        try? recentPresetStore.remember(kind: kind, durationMinutes: normalizedMinutes, usedAt: now)
        recentPresets = (try? recentPresetStore.loadRecentPresets()) ?? recentPresets

        if settings.hapticsEnabled {
            haptics.play(.start)
        }

        _ = await notificationScheduler.requestAuthorizationIfNeeded()
        notificationStatus = await notificationScheduler.authorizationStatus()
        await notificationScheduler.scheduleNotifications(for: newSnapshot, settings: settings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func pauseOrResume() async {
        guard let snapshot else { return }
        let updated: ActiveCycleSnapshot
        if snapshot.status == .paused {
            updated = CycleTimerEngine.resume(snapshot)
            if settings.hapticsEnabled { haptics.play(.resume) }
        } else {
            updated = CycleTimerEngine.pause(snapshot)
            if settings.hapticsEnabled { haptics.play(.pause) }
        }
        self.snapshot = updated
        snapshotStore.save(updated)
        await notificationScheduler.scheduleNotifications(for: updated, settings: settings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func addFiveMinutes() async {
        guard let snapshot else { return }
        let updated = CycleTimerEngine.addTime(snapshot, minutes: 5)
        self.snapshot = updated
        snapshotStore.save(updated)
        await notificationScheduler.scheduleNotifications(for: updated, settings: settings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func restartCycle() async {
        guard let snapshot else { return }
        let restarted = CycleTimerEngine.restart(snapshot)
        self.snapshot = restarted
        snapshotStore.save(restarted)
        try? recentPresetStore.remember(kind: restarted.kind, durationMinutes: Int(restarted.configuredDuration / 60), usedAt: Date())
        recentPresets = (try? recentPresetStore.loadRecentPresets()) ?? recentPresets
        if settings.hapticsEnabled { haptics.play(.start) }
        await notificationScheduler.scheduleNotifications(for: restarted, settings: settings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func snoozeFiveMinutes() async {
        guard let snapshot else { return }
        let snoozed = CycleTimerEngine.snooze(snapshot, minutes: 5)
        self.snapshot = snoozed
        snapshotStore.save(snoozed)
        if settings.hapticsEnabled { haptics.play(.snoozeAccepted) }
        await notificationScheduler.scheduleNotifications(for: snoozed, settings: settings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func markDone() async {
        snapshot = nil
        snapshotStore.save(nil)
        await notificationScheduler.cancelScheduledNotifications()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateSettings(_ newSettings: AppSettings) async {
        settings = newSettings
        try? settingsStore.saveSettings(newSettings)
        if let snapshot {
            await notificationScheduler.scheduleNotifications(for: snapshot, settings: newSettings)
        }
    }

    func refreshTimerState() async {
        guard let snapshot else { return }
        let normalized = CycleTimerEngine.normalize(snapshot)
        if normalized != snapshot {
            self.snapshot = normalized
            snapshotStore.save(normalized)
            await notificationScheduler.scheduleNotifications(for: normalized, settings: settings)
            WidgetCenter.shared.reloadAllTimelines()
            playCompletionIfNeeded()
        }
    }

    func handleNotificationAction(identifier: String) async {
        switch identifier {
        case AppConstants.notificationActionDone:
            await markDone()
        case AppConstants.notificationActionSnooze:
            await snoozeFiveMinutes()
        case AppConstants.notificationActionStartDryer:
            await startDefaultCycle(kind: .dryer)
        default:
            break
        }
    }

    func statusLine(for snapshot: ActiveCycleSnapshot) -> String {
        switch snapshot.status {
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .completed:
            if let completedLabel = snapshot.completedElapsedString() {
                return "Finished \(completedLabel)"
            }
            return "Laundry done"
        case .snoozed:
            return "Snoozed"
        case .idle:
            return "Idle"
        }
    }

    private func playCompletionIfNeeded() {
        guard let snapshot, snapshot.status == .completed, settings.hapticsEnabled else { return }
        guard snapshot.completedAt?.timeIntervalSinceNow ?? -999 > -2 else { return }
        haptics.play(.completion)
    }
}
