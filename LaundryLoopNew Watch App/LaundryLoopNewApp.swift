//
//  LaundryLoopNewApp.swift
//  LaundryLoopNew Watch App
//
//  Created by Viennarz Curtiz on 3/7/26.
//

import Combine
import SwiftUI
import UserNotifications

@main
@MainActor
struct LaundryLoopNew_Watch_AppApp: App {
    @StateObject private var coordinator: CycleCoordinator
    @StateObject private var notificationRouter: NotificationResponseRouter

    init() {
        let coordinator = AppEnvironment.makeCoordinator()
        _coordinator = StateObject(wrappedValue: coordinator)

        let notificationRouter = NotificationResponseRouter(coordinator: coordinator)
        _notificationRouter = StateObject(wrappedValue: notificationRouter)
        notificationRouter.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(coordinator: coordinator)
        }
    }
}

@MainActor
final class NotificationResponseRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private let coordinator: CycleCoordinator

    init(coordinator: CycleCoordinator) {
        self.coordinator = coordinator
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self

        Task { @MainActor in
            await coordinator.configureNotificationsOnLaunch()
        }
    }

    func handleActionIdentifier(_ identifier: String) async {
        await coordinator.handleNotificationAction(identifier: identifier)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor [coordinator] in
            await coordinator.handleNotificationAction(identifier: response.actionIdentifier)
            completionHandler()
        }
    }
}
