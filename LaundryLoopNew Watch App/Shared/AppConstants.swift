import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.me.vnnz.LaundryLoop"
    static let notificationWasherCompletionCategoryIdentifier = "laundry-loop.cycle-actions.washer-complete"
    static let notificationDryerCompletionCategoryIdentifier = "laundry-loop.cycle-actions.dryer-complete"
    static let notificationPrefinishReminderCategoryIdentifier = "laundry-loop.cycle-actions.prefinish"
    static let notificationOverdueReminderCategoryIdentifier = "laundry-loop.cycle-actions.overdue"
    static let notificationActionDone = "laundry-loop.action.done"
    static let notificationActionSnooze = "laundry-loop.action.snooze"
    static let notificationActionStartDryer = "laundry-loop.action.start-dryer"
    static let notificationWasherCompletionIdentifier = "laundry-loop.notification.completion.washer"
    static let notificationDryerCompletionIdentifier = "laundry-loop.notification.completion.dryer"
    static let notificationPrefinishReminderIdentifier = "laundry-loop.notification.reminder.prefinish"
    static let notificationOverdueReminderIdentifierPrefix = "laundry-loop.notification.reminder.overdue"
    static let snapshotDefaultsKey = "activeCycleSnapshot"
    static let widgetKind = "LaundryLoopCycleWidget"
    static let maxRecentPresets = 6
}
