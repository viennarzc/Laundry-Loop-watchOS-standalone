import Foundation

private enum WidgetConstants {
    static let appGroupIdentifier = "group.me.vnnz.LaundryLoop"
    static let snapshotDefaultsKey = "activeCycleSnapshot"
}

enum WidgetCycleKind: String, Codable {
    case washer
    case dryer

    var title: String {
        switch self {
        case .washer: return "Washer"
        case .dryer: return "Dryer"
        }
    }

    var symbolName: String {
        switch self {
        case .washer: return "drop.circle"
        case .dryer: return "wind"
        }
    }
}

enum WidgetCycleStatus: String, Codable {
    case idle
    case running
    case paused
    case completed
    case snoozed
}

struct WidgetCycleSnapshot: Codable, Equatable {
    let id: UUID
    var kind: WidgetCycleKind
    var status: WidgetCycleStatus
    var configuredDuration: TimeInterval
    var countdownDuration: TimeInterval
    var phaseStartedAt: Date
    var scheduledEnd: Date?
    var remainingWhenPaused: TimeInterval?
    var lastModifiedAt: Date
    var completedAt: Date?
    var reminderLeadMinutes: Int

    var nextReminderAt: Date? {
        guard let end = scheduledEnd, reminderLeadMinutes > 0 else {
            return nil
        }
        return end.addingTimeInterval(-TimeInterval(reminderLeadMinutes * 60))
    }
}

enum WidgetSnapshotStore {
    static func load() -> WidgetCycleSnapshot? {
        let defaults = UserDefaults(suiteName: WidgetConstants.appGroupIdentifier) ?? .standard
        guard let data = defaults.data(forKey: WidgetConstants.snapshotDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetCycleSnapshot.self, from: data)
    }

    static func remaining(for snapshot: WidgetCycleSnapshot, now: Date = .now) -> TimeInterval {
        switch snapshot.status {
        case .paused:
            return max(snapshot.remainingWhenPaused ?? snapshot.countdownDuration, 0)
        case .completed:
            return 0
        case .running, .snoozed:
            return max((snapshot.scheduledEnd ?? now).timeIntervalSince(now), 0)
        case .idle:
            return 0
        }
    }

    static func progress(for snapshot: WidgetCycleSnapshot, now: Date = .now) -> Double {
        guard snapshot.countdownDuration > 0 else { return 1 }
        let progress = 1 - (remaining(for: snapshot, now: now) / snapshot.countdownDuration)
        return min(max(progress, 0), 1)
    }

    static func normalized(_ snapshot: WidgetCycleSnapshot, now: Date = .now) -> WidgetCycleSnapshot {
        guard snapshot.status == .running || snapshot.status == .snoozed else { return snapshot }
        guard let end = snapshot.scheduledEnd, end <= now else { return snapshot }
        var completed = snapshot
        completed.status = .completed
        completed.completedAt = end
        completed.scheduledEnd = nil
        completed.remainingWhenPaused = 0
        completed.lastModifiedAt = now
        return completed
    }

    static func stateLine(for snapshot: WidgetCycleSnapshot) -> String {
        switch snapshot.status {
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Done"
        case .snoozed: return "Snoozed"
        case .idle: return "Idle"
        }
    }

    static func durationString(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds.rounded()), 0)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    /// Returns a reasonable refresh cadence for the timeline based on how much time remains.
    static func refreshInterval(for snapshot: WidgetCycleSnapshot?, now: Date = .now) -> TimeInterval {
        guard let snapshot else { return 120 }
        let remaining = remaining(for: snapshot, now: now)
        return max(min(remaining, 60), 20)
    }
}
