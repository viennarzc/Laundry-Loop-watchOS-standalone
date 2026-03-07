import Foundation
import SwiftData

@MainActor
enum AppEnvironment {
    static func makeCoordinator(modelContainer: ModelContainer? = nil) -> CycleCoordinator {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--uitesting")
        let container = modelContainer ?? {
            if isUITesting {
                return (try? PersistenceController.inMemory()) ?? PersistenceController.shared
            }
            return PersistenceController.shared
        }()
        let modelContext = ModelContext(container)
        let notificationScheduler: NotificationScheduling = isUITesting ? NoopNotificationScheduler() : NotificationScheduler()
        let haptics: HapticsPlaying = isUITesting ? NoopHapticsClient() : HapticsClient()
        return CycleCoordinator(
            snapshotStore: ActiveCycleSnapshotStore(),
            settingsStore: SettingsStore(modelContext: modelContext),
            recentPresetStore: RecentPresetStore(modelContext: modelContext),
            notificationScheduler: notificationScheduler,
            haptics: haptics
        )
    }
}
