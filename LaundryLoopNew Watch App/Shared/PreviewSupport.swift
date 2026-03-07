import Foundation
import SwiftData

/// Helper utilities needed to drive SwiftUI previews across the app.
enum PreviewSupport {
    /// Returns a coordinator wired to an in-memory store so previews can read/write without hitting disk.
    static func makeCoordinator() -> CycleCoordinator {
        let container = try? PersistenceController.inMemory()
        return AppEnvironment.makeCoordinator(modelContainer: container)
    }

    /// A running washer snapshot for staging ActiveCycleView previews.
    static var runningSnapshot: ActiveCycleSnapshot {
        let started = CycleTimerEngine.start(kind: .washer, minutes: 30, reminderLeadMinutes: 5, now: Date().addingTimeInterval(-120))
        return CycleTimerEngine.normalize(started, now: Date())
    }

    /// A completed snapshot that represents the end-of-cycle state.
    static var completedSnapshot: ActiveCycleSnapshot {
        var snapshot = runningSnapshot
        let completed = CycleTimerEngine.normalize(snapshot, now: snapshot.scheduledEnd ?? Date())
        snapshot = completed
        return snapshot
    }
}
