//
//  LaundryLoopNewApp.swift
//  LaundryLoopNew Watch App
//
//  Created by Viennarz Curtiz on 3/7/26.
//

import SwiftUI
import UserNotifications

@main
@MainActor
struct LaundryLoopNew_Watch_AppApp: App {
    @StateObject private var coordinator: CycleCoordinator
    private let notificationRouter: NotificationResponseRouter

    init() {
        let coordinator = AppEnvironment.makeCoordinator()
        _coordinator = StateObject(wrappedValue: coordinator)

        let notificationRouter = NotificationResponseRouter(coordinator: coordinator)
        self.notificationRouter = notificationRouter
        notificationRouter.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(coordinator: coordinator)
        }
    }
}

final class NotificationResponseRouter: NSObject, UNUserNotificationCenterDelegate {
    private let handleAction: @Sendable (String) async -> Void
    private let configureNotifications: @Sendable () async -> Void

    init(coordinator: CycleCoordinator) {
        self.handleAction = { identifier in
            await coordinator.handleNotificationAction(identifier: identifier)
        }
        self.configureNotifications = {
            await coordinator.configureNotificationsOnLaunch()
        }
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self

        Task {
            await configureNotifications()
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await handleAction(response.actionIdentifier)
            completionHandler()
        }
    }
}
