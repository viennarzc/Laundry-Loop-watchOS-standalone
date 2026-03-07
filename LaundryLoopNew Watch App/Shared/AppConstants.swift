import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.me.vnnz.LaundryLoop"
    static let notificationCategoryIdentifier = "laundry-loop.cycle-actions"
    static let notificationActionDone = "laundry-loop.action.done"
    static let notificationActionSnooze = "laundry-loop.action.snooze"
    static let notificationActionStartDryer = "laundry-loop.action.start-dryer"
    static let notificationCompletionIdentifier = "laundry-loop.notification.completion"
    static let notificationReminderIdentifier = "laundry-loop.notification.reminder"
    static let snapshotDefaultsKey = "activeCycleSnapshot"
    static let widgetKind = "LaundryLoopCycleWidget"
    static let maxRecentPresets = 6
}
