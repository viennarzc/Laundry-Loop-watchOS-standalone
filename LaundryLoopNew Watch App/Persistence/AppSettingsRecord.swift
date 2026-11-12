import Foundation
import SwiftData

@Model
final class AppSettingsRecord {
    var createdAt: Date
    var defaultWasherMinutes: Int
    var defaultDryerMinutes: Int
    var reminderLeadMinutes: Int
    var hapticsEnabled: Bool
    // Existing stores receive the original reminder cadence during migration.
    var reminderProfileRawValue: String = "persistent"

    init(
        createdAt: Date = .now,
        defaultWasherMinutes: Int = AppSettings.default.defaultWasherMinutes,
        defaultDryerMinutes: Int = AppSettings.default.defaultDryerMinutes,
        reminderLeadMinutes: Int = AppSettings.default.reminderLeadMinutes,
        hapticsEnabled: Bool = AppSettings.default.hapticsEnabled,
        reminderProfile: ReminderProfile = AppSettings.default.reminderProfile
    ) {
        self.createdAt = createdAt
        self.defaultWasherMinutes = defaultWasherMinutes
        self.defaultDryerMinutes = defaultDryerMinutes
        self.reminderLeadMinutes = reminderLeadMinutes
        self.hapticsEnabled = hapticsEnabled
        self.reminderProfileRawValue = reminderProfile.rawValue
    }
}
