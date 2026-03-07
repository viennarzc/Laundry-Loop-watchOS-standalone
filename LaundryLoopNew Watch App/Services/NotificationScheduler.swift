import Foundation
import UserNotifications

final class NotificationScheduler: NotificationScheduling {
    func registerCategories() async {
        let actions = [
            UNNotificationAction(identifier: AppConstants.notificationActionDone, title: "Done"),
            UNNotificationAction(identifier: AppConstants.notificationActionSnooze, title: "Snooze 5 min"),
            UNNotificationAction(identifier: AppConstants.notificationActionStartDryer, title: "Start Dryer"),
        ]
        let category = UNNotificationCategory(
            identifier: AppConstants.notificationCategoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        await registerCategories()
        let center = UNUserNotificationCenter.current()
        let currentSettings = await center.notificationSettings()
        switch currentSettings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    func scheduleNotifications(for snapshot: ActiveCycleSnapshot, settings: AppSettings) async {
        await cancelScheduledNotifications()
        guard snapshot.status.isCountdownActive, let scheduledEnd = snapshot.scheduledEnd else { return }
        let center = UNUserNotificationCenter.current()

        let completionContent = UNMutableNotificationContent()
        completionContent.title = "\(snapshot.kind.title) finished"
        completionContent.body = "Laundry Loop is ready when you are."
        completionContent.sound = .default
        completionContent.categoryIdentifier = AppConstants.notificationCategoryIdentifier

        let completionInterval = max(scheduledEnd.timeIntervalSinceNow, 1)
        let completionRequest = UNNotificationRequest(
            identifier: AppConstants.notificationCompletionIdentifier,
            content: completionContent,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: completionInterval, repeats: false)
        )
        try? await center.add(completionRequest)

        let reminderLead = TimeInterval(settings.reminderLeadMinutes * 60)
        if reminderLead > 0, completionInterval > reminderLead {
            let reminderContent = UNMutableNotificationContent()
            reminderContent.title = "\(snapshot.kind.title) almost done"
            reminderContent.body = "\(settings.reminderLeadMinutes) minutes left."
            reminderContent.sound = .default
            reminderContent.categoryIdentifier = AppConstants.notificationCategoryIdentifier
            let reminderRequest = UNNotificationRequest(
                identifier: AppConstants.notificationReminderIdentifier,
                content: reminderContent,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: completionInterval - reminderLead, repeats: false)
            )
            try? await center.add(reminderRequest)
        }
    }

    func cancelScheduledNotifications() async {
        let identifiers = [
            AppConstants.notificationCompletionIdentifier,
            AppConstants.notificationReminderIdentifier,
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

struct NoopNotificationScheduler: NotificationScheduling {
    var status: UNAuthorizationStatus = .authorized

    func registerCategories() async {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        true
    }

    func scheduleNotifications(for snapshot: ActiveCycleSnapshot, settings: AppSettings) async {}

    func cancelScheduledNotifications() async {}
}
