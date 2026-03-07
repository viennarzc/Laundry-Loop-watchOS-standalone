import Foundation
import SwiftData

@Model
final class AppSettingsRecord {
    var createdAt: Date
    var defaultWasherMinutes: Int
    var defaultDryerMinutes: Int
    var reminderLeadMinutes: Int
    var hapticsEnabled: Bool

    init(
        createdAt: Date = .now,
        defaultWasherMinutes: Int = AppSettings.default.defaultWasherMinutes,
        defaultDryerMinutes: Int = AppSettings.default.defaultDryerMinutes,
        reminderLeadMinutes: Int = AppSettings.default.reminderLeadMinutes,
        hapticsEnabled: Bool = AppSettings.default.hapticsEnabled
    ) {
        self.createdAt = createdAt
        self.defaultWasherMinutes = defaultWasherMinutes
        self.defaultDryerMinutes = defaultDryerMinutes
        self.reminderLeadMinutes = reminderLeadMinutes
        self.hapticsEnabled = hapticsEnabled
    }
}
