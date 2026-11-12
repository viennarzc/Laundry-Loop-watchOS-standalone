import Foundation
import UserNotifications

final class NotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let center: UserNotificationCentering
    private let operationLock = NSLock()
    private var previousOperation: Task<Void, Never>?

    init(center: UserNotificationCentering = UNUserNotificationCenter.current()) {
        self.center = center
    }

    func registerCategories() async {
        let doneAndSnoozeActions = [
            UNNotificationAction(identifier: AppConstants.notificationActionDone, title: "Finish"),
            UNNotificationAction(identifier: AppConstants.notificationActionSnooze, title: "Snooze 5 min"),
        ]
        let washerCompletionActions = doneAndSnoozeActions + [
            UNNotificationAction(identifier: AppConstants.notificationActionStartDryer, title: "Start Dryer"),
        ]
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(
                identifier: AppConstants.notificationWasherCompletionCategoryIdentifier,
                actions: washerCompletionActions,
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: AppConstants.notificationDryerCompletionCategoryIdentifier,
                actions: doneAndSnoozeActions,
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: AppConstants.notificationPrefinishReminderCategoryIdentifier,
                actions: doneAndSnoozeActions,
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: AppConstants.notificationOverdueReminderCategoryIdentifier,
                actions: doneAndSnoozeActions,
                intentIdentifiers: [],
                options: []
            ),
        ]
        center.setNotificationCategories(categories)
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.authorizationStatus()
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        await registerCategories()
        switch await center.authorizationStatus() {
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
        let operation = enqueue { [self] in
            await performSchedule(for: snapshot, settings: settings)
        }
        await operation.value
    }

    private func performSchedule(for snapshot: ActiveCycleSnapshot, settings: AppSettings) async {
        await clearPendingNotifications()
        let authorization = await center.authorizationStatus()
        switch authorization {
        case .authorized, .provisional, .ephemeral: break
        default: return
        }

        switch snapshot.status {
        case .running, .snoozed:
            guard let scheduledEnd = snapshot.scheduledEnd else { return }

            let completionContent = UNMutableNotificationContent()
            completionContent.title = "\(snapshot.kind.title) finished"
            completionContent.body = "Laundry Loop is ready when you are."
            completionContent.sound = .default
            completionContent.categoryIdentifier = completionCategoryIdentifier(for: snapshot.kind)

            let completionInterval = max(scheduledEnd.timeIntervalSinceNow, 1)
            let completionRequest = UNNotificationRequest(
                identifier: completionRequestIdentifier(for: snapshot.kind),
                content: completionContent,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: completionInterval, repeats: false)
            )
            try? await center.add(completionRequest)

            let reminderLead = TimeInterval(settings.reminderLeadMinutes * 60)
            if settings.reminderProfile.includesPrefinish, reminderLead > 0, completionInterval > reminderLead {
                let reminderContent = UNMutableNotificationContent()
                reminderContent.title = "\(snapshot.kind.title) almost done"
                reminderContent.body = "\(settings.reminderLeadMinutes) minutes left."
                reminderContent.sound = .default
                reminderContent.categoryIdentifier = AppConstants.notificationPrefinishReminderCategoryIdentifier
                let reminderRequest = UNNotificationRequest(
                    identifier: AppConstants.notificationPrefinishReminderIdentifier,
                    content: reminderContent,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: completionInterval - reminderLead, repeats: false)
                )
                try? await center.add(reminderRequest)
            }

            await scheduleOverdueReminders(kind: snapshot.kind, completedAt: scheduledEnd, profile: settings.reminderProfile)

        case .completed, .overdue:
            guard let completedAt = snapshot.completedAt else { return }
            await scheduleOverdueReminders(kind: snapshot.kind, completedAt: completedAt, profile: settings.reminderProfile)

        case .paused, .idle:
            break
        }
    }

    func cancelScheduledNotifications() async {
        let operation = enqueue { [self] in
            let identifiers = allNotificationIdentifiers
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
        await operation.value
    }

    private func scheduleOverdueReminders(kind: CycleKind, completedAt: Date, profile: ReminderProfile) async {
        for offset in profile.overdueOffsets {
            let fireDate = completedAt.addingTimeInterval(offset)
            let interval = fireDate.timeIntervalSinceNow
            guard interval > 0 else { continue }

            let reminderContent = UNMutableNotificationContent()
            reminderContent.title = "\(kind.title) still needs attention"
            reminderContent.body = "Finished \(DurationFormatter.elapsedString(since: completedAt, now: fireDate))."
            reminderContent.sound = .default
            reminderContent.categoryIdentifier = AppConstants.notificationOverdueReminderCategoryIdentifier

            let request = UNNotificationRequest(
                identifier: overdueReminderIdentifier(for: offset),
                content: reminderContent,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            )
            try? await center.add(request)
        }
    }

    private func completionCategoryIdentifier(for kind: CycleKind) -> String {
        switch kind {
        case .washer:
            return AppConstants.notificationWasherCompletionCategoryIdentifier
        case .dryer:
            return AppConstants.notificationDryerCompletionCategoryIdentifier
        }
    }

    private func completionRequestIdentifier(for kind: CycleKind) -> String {
        switch kind {
        case .washer:
            return AppConstants.notificationWasherCompletionIdentifier
        case .dryer:
            return AppConstants.notificationDryerCompletionIdentifier
        }
    }

    private func overdueReminderIdentifier(for offset: TimeInterval) -> String {
        "\(AppConstants.notificationOverdueReminderIdentifierPrefix).\(Int(offset / 60))"
    }

    private var allNotificationIdentifiers: [String] {
        [
            AppConstants.notificationWasherCompletionIdentifier,
            AppConstants.notificationDryerCompletionIdentifier,
            AppConstants.notificationPrefinishReminderIdentifier,
        ] + ReminderProfile.persistent.overdueOffsets.map(overdueReminderIdentifier(for:))
    }

    private func clearPendingNotifications() async {
        center.removePendingNotificationRequests(withIdentifiers: allNotificationIdentifiers)
    }

    private func enqueue(_ action: @escaping @Sendable () async -> Void) -> Task<Void, Never> {
        operationLock.lock()
        defer { operationLock.unlock() }
        let previous = previousOperation
        let operation = Task {
            await previous?.value
            await action()
        }
        previousOperation = operation
        return operation
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
