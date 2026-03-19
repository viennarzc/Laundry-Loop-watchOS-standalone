import Foundation
import Testing
import UserNotifications
@testable import Laundry_Loop_Watch_App

struct LaundryLoopNew_Watch_AppTests {
    @Test func notificationRouterForwardsStartDryerActionToCoordinator() async throws {
        let stores = TestStores(snapshot: makeCompletedSnapshot(kind: .washer))
        let scheduler = MockNotificationScheduler()
        let coordinator = await makeCoordinator(stores: stores, scheduler: scheduler)
        let router = await MainActor.run { NotificationResponseRouter(coordinator: coordinator) }

        await MainActor.run {
            router.configure()
        }
        await router.handleActionIdentifier(AppConstants.notificationActionStartDryer)

        guard let snapshot = await MainActor.run(body: { coordinator.snapshot }) else {
            Issue.record("Expected a dryer snapshot after the router forwards Start Dryer.")
            return
        }
        #expect(snapshot.kind == .dryer)
        #expect(snapshot.status == .running)
        #expect(stores.snapshotStore.snapshot?.kind == .dryer)
    }

    @Test func startDryerActionStartsDryerCycleFromCompletedWasher() async throws {
        let stores = TestStores(snapshot: makeCompletedSnapshot(kind: .washer))
        let scheduler = MockNotificationScheduler()
        let coordinator = await makeCoordinator(stores: stores, scheduler: scheduler)

        await coordinator.handleNotificationAction(identifier: AppConstants.notificationActionStartDryer)

        guard let snapshot = await MainActor.run(body: { coordinator.snapshot }) else {
            Issue.record("Expected a dryer snapshot after handling Start Dryer.")
            return
        }
        #expect(snapshot.kind == .dryer)
        #expect(snapshot.status == .running)
        #expect(scheduler.scheduledSnapshots.last?.kind == .dryer)
        #expect(stores.snapshotStore.snapshot?.kind == .dryer)
    }

    @Test func doneActionClearsSnapshotAndCancelsNotifications() async {
        let stores = TestStores(snapshot: makeCompletedSnapshot(kind: .washer))
        let scheduler = MockNotificationScheduler()
        let coordinator = await makeCoordinator(stores: stores, scheduler: scheduler)

        await coordinator.handleNotificationAction(identifier: AppConstants.notificationActionDone)

        let snapshot = await MainActor.run(body: { coordinator.snapshot })
        #expect(snapshot == nil)
        #expect(stores.snapshotStore.snapshot == nil)
        #expect(scheduler.cancelCallCount == 1)
    }

    @Test func snoozeActionMovesSnapshotIntoSnoozedStateAndReschedules() async throws {
        let stores = TestStores(snapshot: makeCompletedSnapshot(kind: .dryer))
        let scheduler = MockNotificationScheduler()
        let coordinator = await makeCoordinator(stores: stores, scheduler: scheduler)

        await coordinator.handleNotificationAction(identifier: AppConstants.notificationActionSnooze)

        guard let snapshot = await MainActor.run(body: { coordinator.snapshot }) else {
            Issue.record("Expected a snoozed snapshot after handling Snooze.")
            return
        }
        #expect(snapshot.kind == .dryer)
        #expect(snapshot.status == .snoozed)
        #expect(snapshot.countdownDuration == 5 * 60)
        #expect(snapshot.scheduledEnd != nil)
        #expect(scheduler.scheduledSnapshots.last?.status == .snoozed)
    }

    @Test func refreshFromPersistenceSchedulesCompletedSnapshotForOverdueReminders() async throws {
        let stores = TestStores(snapshot: makeExpiredRunningSnapshot(kind: .washer))
        let scheduler = MockNotificationScheduler()
        let coordinator = await makeCoordinator(stores: stores, scheduler: scheduler)

        await coordinator.refreshFromPersistence()

        guard let snapshot = await MainActor.run(body: { coordinator.snapshot }) else {
            Issue.record("Expected a completed snapshot after refresh.")
            return
        }
        #expect(snapshot.status == .completed)
        #expect(snapshot.completedAt != nil)
        #expect(scheduler.scheduledSnapshots.last?.status == .completed)
    }

    @Test func registerCategoriesSplitsWasherDryerAndReminderActions() async throws {
        let center = MockUserNotificationCenter()
        let scheduler = makeNotificationScheduler(center: center)

        await scheduler.registerCategories()

        let categories = center.categories
        let washerCategory = try #require(categories.first { $0.identifier == AppConstants.notificationWasherCompletionCategoryIdentifier })
        let dryerCategory = try #require(categories.first { $0.identifier == AppConstants.notificationDryerCompletionCategoryIdentifier })
        let prefinishCategory = try #require(categories.first { $0.identifier == AppConstants.notificationPrefinishReminderCategoryIdentifier })
        let overdueCategory = try #require(categories.first { $0.identifier == AppConstants.notificationOverdueReminderCategoryIdentifier })

        #expect(washerCategory.actions.map { $0.identifier } == [
            AppConstants.notificationActionDone,
            AppConstants.notificationActionSnooze,
            AppConstants.notificationActionStartDryer,
        ])
        #expect(dryerCategory.actions.map { $0.identifier } == [
            AppConstants.notificationActionDone,
            AppConstants.notificationActionSnooze,
        ])
        #expect(prefinishCategory.actions.map { $0.identifier } == [
            AppConstants.notificationActionDone,
            AppConstants.notificationActionSnooze,
        ])
        #expect(overdueCategory.actions.map { $0.identifier } == [
            AppConstants.notificationActionDone,
            AppConstants.notificationActionSnooze,
        ])
    }

    @Test func washerSchedulingUsesCompletionPrefinishAndOverdueCadence() async throws {
        let center = MockUserNotificationCenter()
        let scheduler = makeNotificationScheduler(center: center)
        let settings = AppSettings.default
        let now = Date()
        let snapshot = CycleTimerEngine.start(kind: .washer, minutes: 60, reminderLeadMinutes: settings.reminderLeadMinutes, now: now)

        await scheduler.scheduleNotifications(for: snapshot, settings: settings)

        let completion = try #require(center.request(id: AppConstants.notificationWasherCompletionIdentifier))
        let prefinish = try #require(center.request(id: AppConstants.notificationPrefinishReminderIdentifier))
        let overdue15 = try #require(center.request(id: "\(AppConstants.notificationOverdueReminderIdentifierPrefix).15"))
        let overdue45 = try #require(center.request(id: "\(AppConstants.notificationOverdueReminderIdentifierPrefix).45"))
        let overdue105 = try #require(center.request(id: "\(AppConstants.notificationOverdueReminderIdentifierPrefix).105"))

        #expect(completion.content.categoryIdentifier == AppConstants.notificationWasherCompletionCategoryIdentifier)
        #expect(prefinish.content.categoryIdentifier == AppConstants.notificationPrefinishReminderCategoryIdentifier)
        #expect(overdue15.content.categoryIdentifier == AppConstants.notificationOverdueReminderCategoryIdentifier)
        #expect(overdue45.content.categoryIdentifier == AppConstants.notificationOverdueReminderCategoryIdentifier)
        #expect(overdue105.content.categoryIdentifier == AppConstants.notificationOverdueReminderCategoryIdentifier)
        #expect(hasTriggerInterval(completion, expected: 60 * 60))
        #expect(hasTriggerInterval(prefinish, expected: 55 * 60))
        #expect(hasTriggerInterval(overdue15, expected: 75 * 60))
        #expect(hasTriggerInterval(overdue45, expected: 105 * 60))
        #expect(hasTriggerInterval(overdue105, expected: 165 * 60))
    }

    @Test func completedSnapshotSchedulesOnlyRemainingOverdueReminders() async {
        let center = MockUserNotificationCenter()
        let scheduler = makeNotificationScheduler(center: center)
        let completedAt = Date().addingTimeInterval(-20 * 60)
        let snapshot = ActiveCycleSnapshot(
            id: UUID(),
            kind: .dryer,
            status: .completed,
            configuredDuration: 60 * 60,
            countdownDuration: 60 * 60,
            phaseStartedAt: completedAt.addingTimeInterval(-(60 * 60)),
            scheduledEnd: nil,
            remainingWhenPaused: 0,
            lastModifiedAt: completedAt,
            completedAt: completedAt,
            reminderLeadMinutes: 5
        )

        await scheduler.scheduleNotifications(for: snapshot, settings: .default)

        #expect(center.request(id: AppConstants.notificationDryerCompletionIdentifier) == nil)
        #expect(center.request(id: AppConstants.notificationPrefinishReminderIdentifier) == nil)
        #expect(center.request(id: "\(AppConstants.notificationOverdueReminderIdentifierPrefix).15") == nil)
        #expect(center.request(id: "\(AppConstants.notificationOverdueReminderIdentifierPrefix).45") != nil)
        #expect(center.request(id: "\(AppConstants.notificationOverdueReminderIdentifierPrefix).105") != nil)
    }

    @Test func normalizeMarksExpiredRunningSnapshotCompleted() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let snapshot = ActiveCycleSnapshot(
            id: UUID(),
            kind: .washer,
            status: .running,
            configuredDuration: 20 * 60,
            countdownDuration: 20 * 60,
            phaseStartedAt: now.addingTimeInterval(-(25 * 60)),
            scheduledEnd: now.addingTimeInterval(-5),
            remainingWhenPaused: nil,
            lastModifiedAt: now.addingTimeInterval(-(30 * 60)),
            completedAt: nil,
            reminderLeadMinutes: 5
        )

        let normalized = CycleTimerEngine.normalize(snapshot, now: now)

        #expect(normalized.status == .completed)
        #expect(normalized.completedAt == now.addingTimeInterval(-5))
        #expect(normalized.scheduledEnd == nil)
        #expect(normalized.remainingWhenPaused == 0)
        #expect(normalized.lastModifiedAt == now)
    }

    @Test func pauseStoresRemainingTimeAndResumeRestoresSchedule() {
        let now = Date(timeIntervalSinceReferenceDate: 2_000)
        let running = ActiveCycleSnapshot(
            id: UUID(),
            kind: .dryer,
            status: .running,
            configuredDuration: 30 * 60,
            countdownDuration: 30 * 60,
            phaseStartedAt: now.addingTimeInterval(-(10 * 60)),
            scheduledEnd: now.addingTimeInterval(20 * 60),
            remainingWhenPaused: nil,
            lastModifiedAt: now.addingTimeInterval(-(10 * 60)),
            completedAt: nil,
            reminderLeadMinutes: 5
        )

        let paused = CycleTimerEngine.pause(running, now: now)
        let resumeTime = now.addingTimeInterval(90)
        let resumed = CycleTimerEngine.resume(paused, now: resumeTime)

        #expect(paused.status == .paused)
        #expect(paused.remainingWhenPaused == TimeInterval(20 * 60))
        #expect(paused.scheduledEnd == nil)
        #expect(resumed.status == .running)
        #expect(resumed.phaseStartedAt == resumeTime)
        #expect(resumed.scheduledEnd == resumeTime.addingTimeInterval(20 * 60))
        #expect(resumed.remainingWhenPaused == nil)
    }

    @Test func addTimeExtendsPausedAndSnoozedSnapshotsDifferently() {
        let now = Date(timeIntervalSinceReferenceDate: 3_000)
        let paused = ActiveCycleSnapshot(
            id: UUID(),
            kind: .washer,
            status: .paused,
            configuredDuration: 40 * 60,
            countdownDuration: 15 * 60,
            phaseStartedAt: now.addingTimeInterval(-(25 * 60)),
            scheduledEnd: nil,
            remainingWhenPaused: 15 * 60,
            lastModifiedAt: now,
            completedAt: nil,
            reminderLeadMinutes: 5
        )
        let snoozed = ActiveCycleSnapshot(
            id: UUID(),
            kind: .dryer,
            status: .snoozed,
            configuredDuration: 60 * 60,
            countdownDuration: 5 * 60,
            phaseStartedAt: now,
            scheduledEnd: now.addingTimeInterval(5 * 60),
            remainingWhenPaused: nil,
            lastModifiedAt: now,
            completedAt: nil,
            reminderLeadMinutes: 5
        )

        let pausedUpdated = CycleTimerEngine.addTime(paused, minutes: 5, now: now)
        let snoozedUpdated = CycleTimerEngine.addTime(snoozed, minutes: 5, now: now)

        #expect(pausedUpdated.configuredDuration == 45 * 60)
        #expect(pausedUpdated.countdownDuration == 20 * 60)
        #expect(pausedUpdated.remainingWhenPaused == TimeInterval(20 * 60))
        #expect(snoozedUpdated.configuredDuration == 65 * 60)
        #expect(snoozedUpdated.countdownDuration == 10 * 60)
        #expect(snoozedUpdated.scheduledEnd == now.addingTimeInterval(10 * 60))
    }

    @Test func restartPreservesKindAndReminderLeadWhileResettingTimer() {
        let now = Date(timeIntervalSinceReferenceDate: 4_000)
        let snapshot = ActiveCycleSnapshot(
            id: UUID(),
            kind: .dryer,
            status: .completed,
            configuredDuration: 47 * 60,
            countdownDuration: 5 * 60,
            phaseStartedAt: now.addingTimeInterval(-(50 * 60)),
            scheduledEnd: nil,
            remainingWhenPaused: 0,
            lastModifiedAt: now.addingTimeInterval(-(2 * 60)),
            completedAt: now.addingTimeInterval(-(2 * 60)),
            reminderLeadMinutes: 9
        )

        let restarted = CycleTimerEngine.restart(snapshot, now: now)

        #expect(restarted.kind == .dryer)
        #expect(restarted.status == .running)
        #expect(restarted.phaseStartedAt == now)
        #expect(restarted.scheduledEnd == now.addingTimeInterval(47 * 60))
        #expect(restarted.countdownDuration == 47 * 60)
        #expect(restarted.reminderLeadMinutes == 9)
    }

    @Test func activeSnapshotReminderAndCompletionLabelsUseExpectedFormatting() {
        let now = Date(timeIntervalSinceReferenceDate: 5_000)
        let running = ActiveCycleSnapshot(
            id: UUID(),
            kind: .washer,
            status: .running,
            configuredDuration: 30 * 60,
            countdownDuration: 30 * 60,
            phaseStartedAt: now,
            scheduledEnd: now.addingTimeInterval(30 * 60),
            remainingWhenPaused: nil,
            lastModifiedAt: now,
            completedAt: nil,
            reminderLeadMinutes: 5
        )
        let completed = ActiveCycleSnapshot(
            id: UUID(),
            kind: .washer,
            status: .completed,
            configuredDuration: 30 * 60,
            countdownDuration: 30 * 60,
            phaseStartedAt: now.addingTimeInterval(-(35 * 60)),
            scheduledEnd: nil,
            remainingWhenPaused: 0,
            lastModifiedAt: now,
            completedAt: now.addingTimeInterval(-(90 * 60)),
            reminderLeadMinutes: 5
        )

        #expect(running.nextReminderAt == now.addingTimeInterval(25 * 60))
        #expect(completed.completedElapsedString(now: now) == "1 hr ago")
    }

    @Test func durationFormatterHandlesMinuteClockAndElapsedCases() {
        let reference = Date(timeIntervalSince1970: 1_700_000_000)

        #expect(DurationFormatter.minutesString(seconds: 125) == "02:05")
        #expect(DurationFormatter.shortLabel(minutes: 45) == "45m")
        #expect(DurationFormatter.elapsedString(since: reference.addingTimeInterval(-30), now: reference) == "just now")
        #expect(DurationFormatter.elapsedString(since: reference.addingTimeInterval(-(12 * 60)), now: reference) == "12 min ago")
        #expect(DurationFormatter.elapsedString(since: reference.addingTimeInterval(-(3 * 60 * 60)), now: reference) == "3 hr ago")
        #expect(DurationFormatter.elapsedString(since: reference.addingTimeInterval(-(2 * 86_400)), now: reference) == "2 days ago")
    }

    @MainActor
    private func makeCoordinator(stores: TestStores, scheduler: MockNotificationScheduler) -> CycleCoordinator {
        CycleCoordinator(
            snapshotStore: stores.snapshotStore,
            settingsStore: stores.settingsStore,
            recentPresetStore: stores.recentPresetStore,
            notificationScheduler: scheduler,
            haptics: SilentHaptics()
        )
    }

    private func makeNotificationScheduler(center: MockUserNotificationCenter) -> NotificationScheduler {
        NotificationScheduler(center: center)
    }

    private func makeCompletedSnapshot(kind: CycleKind) -> ActiveCycleSnapshot {
        let completedAt = Date().addingTimeInterval(-2 * 60)
        return ActiveCycleSnapshot(
            id: UUID(),
            kind: kind,
            status: .completed,
            configuredDuration: 45 * 60,
            countdownDuration: 45 * 60,
            phaseStartedAt: completedAt.addingTimeInterval(-(45 * 60)),
            scheduledEnd: nil,
            remainingWhenPaused: 0,
            lastModifiedAt: completedAt,
            completedAt: completedAt,
            reminderLeadMinutes: 5
        )
    }

    private func makeExpiredRunningSnapshot(kind: CycleKind) -> ActiveCycleSnapshot {
        let end = Date().addingTimeInterval(-30)
        return ActiveCycleSnapshot(
            id: UUID(),
            kind: kind,
            status: .running,
            configuredDuration: 45 * 60,
            countdownDuration: 45 * 60,
            phaseStartedAt: end.addingTimeInterval(-(45 * 60)),
            scheduledEnd: end,
            remainingWhenPaused: nil,
            lastModifiedAt: end,
            completedAt: nil,
            reminderLeadMinutes: 5
        )
    }

    private func hasTriggerInterval(
        _ request: UNNotificationRequest,
        expected: TimeInterval,
        tolerance: TimeInterval = 0.25
    ) -> Bool {
        guard let actual = request.triggerInterval else {
            return false
        }
        return abs(actual - expected) <= tolerance
    }
}

private struct TestStores {
    let snapshotStore: InMemorySnapshotStore
    let settingsStore: InMemorySettingsStore
    let recentPresetStore: InMemoryRecentPresetStore

    init(snapshot: ActiveCycleSnapshot? = nil, settings: AppSettings = .default) {
        self.snapshotStore = InMemorySnapshotStore(snapshot: snapshot)
        self.settingsStore = InMemorySettingsStore(settings: settings)
        self.recentPresetStore = InMemoryRecentPresetStore()
    }
}

private final class InMemorySnapshotStore: SnapshotStoring, @unchecked Sendable {
    var snapshot: ActiveCycleSnapshot?

    init(snapshot: ActiveCycleSnapshot?) {
        self.snapshot = snapshot
    }

    func load() -> ActiveCycleSnapshot? {
        snapshot
    }

    func save(_ snapshot: ActiveCycleSnapshot?) {
        self.snapshot = snapshot
    }
}

private final class InMemorySettingsStore: SettingsStoring, @unchecked Sendable {
    var settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func loadSettings() throws -> AppSettings {
        settings
    }

    func saveSettings(_ settings: AppSettings) throws {
        self.settings = settings
    }
}

private final class InMemoryRecentPresetStore: RecentPresetStoring, @unchecked Sendable {
    private var presets: [RecentPreset] = []

    func loadRecentPresets() throws -> [RecentPreset] {
        presets
    }

    func remember(kind: CycleKind, durationMinutes: Int, usedAt: Date) throws {
        presets.insert(
            RecentPreset(id: UUID(), kind: kind, durationMinutes: durationMinutes, lastUsedAt: usedAt),
            at: 0
        )
    }
}

private final class MockNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    var registered = false
    var scheduledSnapshots: [ActiveCycleSnapshot] = []
    var cancelCallCount = 0

    func registerCategories() async {
        registered = true
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        .authorized
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        true
    }

    func scheduleNotifications(for snapshot: ActiveCycleSnapshot, settings: AppSettings) async {
        scheduledSnapshots.append(snapshot)
    }

    func cancelScheduledNotifications() async {
        cancelCallCount += 1
    }
}

private final class SilentHaptics: HapticsPlaying, @unchecked Sendable {
    func play(_ event: LaundryHapticEvent) {}
}

private final class MockUserNotificationCenter: UserNotificationCentering, @unchecked Sendable {
    private let lock = NSLock()
    private var storedCategories: Set<UNNotificationCategory> = []
    private var storedRequests: [UNNotificationRequest] = []
    private var storedRemovedPendingIdentifiers: [String] = []
    private var storedRemovedDeliveredIdentifiers: [String] = []

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        lock.withLock {
            storedCategories = categories
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        .authorized
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) async throws {
        lock.withLock {
            storedRequests.removeAll { $0.identifier == request.identifier }
            storedRequests.append(request)
        }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        lock.withLock {
            storedRemovedPendingIdentifiers.append(contentsOf: identifiers)
            storedRequests.removeAll { identifiers.contains($0.identifier) }
        }
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        lock.withLock {
            storedRemovedDeliveredIdentifiers.append(contentsOf: identifiers)
        }
    }

    var categories: Set<UNNotificationCategory> {
        lock.withLock { storedCategories }
    }

    func request(id: String) -> UNNotificationRequest? {
        lock.withLock {
            storedRequests.first { $0.identifier == id }
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

private extension UNNotificationRequest {
    var triggerInterval: TimeInterval? {
        (trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval
    }
}
