import Foundation

struct AppSettings: Equatable, Sendable {
    var defaultWasherMinutes: Int
    var defaultDryerMinutes: Int
    var reminderLeadMinutes: Int
    var hapticsEnabled: Bool
    var reminderProfile: ReminderProfile = .standard

    static let `default` = AppSettings(
        defaultWasherMinutes: 45,
        defaultDryerMinutes: 60,
        reminderLeadMinutes: 5,
        hapticsEnabled: true,
        reminderProfile: .standard
    )
}
