import Foundation
import SwiftData
import UserNotifications

@MainActor
enum AppEnvironment {
    static func makeCoordinator(modelContainer: ModelContainer? = nil) -> CycleCoordinator {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--uitesting")
        if isUITesting, modelContainer == nil {
            return makeUITestCoordinator(arguments: arguments)
        }
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

    private static func makeUITestCoordinator(arguments: [String]) -> CycleCoordinator {
        let rawID = ProcessInfo.processInfo.environment["LAUNDRY_LOOP_UI_TEST_ID"] ?? ""
        guard let id = UUID(uuidString: rawID) else {
            fatalError("UI tests require an isolated LAUNDRY_LOOP_UI_TEST_ID")
        }
        let suite = "laundry-loop-uitest.\(id.uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            fatalError("Could not create isolated UI test defaults")
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite, isDirectory: true)
        if arguments.contains("--uitesting-reset") {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let schema = Schema([AppSettingsRecord.self, RecentPresetRecord.self])
            let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("LaundryLoop.store"))
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let snapshotStore = ActiveCycleSnapshotStore(defaults: defaults)
            if arguments.contains("--uitesting-seed-completed-washer") {
                let start = Date().addingTimeInterval(-46 * 60)
                let running = CycleTimerEngine.start(kind: .washer, minutes: 45, now: start)
                snapshotStore.save(CycleTimerEngine.normalize(running))
            }
            let status: UNAuthorizationStatus = arguments.contains("--uitesting-denied") ? .denied : .authorized
            let context = ModelContext(container)
            return CycleCoordinator(
                snapshotStore: snapshotStore,
                settingsStore: SettingsStore(modelContext: context),
                recentPresetStore: RecentPresetStore(modelContext: context),
                notificationScheduler: NoopNotificationScheduler(status: status),
                haptics: NoopHapticsClient()
            )
        } catch {
            fatalError("Could not create isolated UI test store: \(error)")
        }
    }
}
