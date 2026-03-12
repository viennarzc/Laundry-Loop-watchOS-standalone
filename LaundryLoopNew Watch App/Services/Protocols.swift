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

public protocol UserNotificationCentering: AnyObject {
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

protocol HapticsPlaying: Sendable {
    func play(_ event: LaundryHapticEvent)
}

extension UNUserNotificationCenter: UserNotificationCentering {
    public func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }
}
