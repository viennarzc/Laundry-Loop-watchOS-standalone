import Foundation
import UserNotifications

protocol SnapshotStoring: Sendable {
    func load() -> ActiveCycleSnapshot?
    func save(_ snapshot: ActiveCycleSnapshot?)
}

protocol SettingsStoring: Sendable {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}

protocol RecentPresetStoring: Sendable {
    func loadRecentPresets() throws -> [RecentPreset]
    func remember(kind: CycleKind, durationMinutes: Int, usedAt: Date) throws
}

protocol NotificationScheduling: Sendable {
    func registerCategories() async
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorizationIfNeeded() async -> Bool
    func scheduleNotifications(for snapshot: ActiveCycleSnapshot, settings: AppSettings) async
    func cancelScheduledNotifications() async
}

protocol HapticsPlaying: Sendable {
    func play(_ event: LaundryHapticEvent)
}
