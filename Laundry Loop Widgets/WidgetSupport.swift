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

    var displayEndDate: Date? {
        guard status == .running || status == .snoozed else {
            return nil
        }
        return scheduledEnd
    }

    var displayStateLine: String {
        switch status {
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed:
            if let completedAt {
                return "Finished \(WidgetSnapshotStore.elapsedString(since: completedAt))"
            }
            return "Done"
        case .snoozed: return "Snoozed"
        case .idle: return "Idle"
        }
    }

    var completedDisplayLabel: String {
        guard status == .completed, let completedAt else {
            return "Laundry done"
        }
        return "Finished \(WidgetSnapshotStore.elapsedString(since: completedAt))"
    }

    var completedCompactLabel: String {
        guard status == .completed, let completedAt else {
            return "Done"
        }
        return WidgetSnapshotStore.compactElapsedString(since: completedAt)
    }

    var displayRemainingString: String? {
        guard status == .paused else {
            return nil
        }
        return WidgetSnapshotStore.durationString(WidgetSnapshotStore.remaining(for: self))
    }
}

/// `WidgetSnapshotStore` provides utility methods for managing and accessing `WidgetCycleSnapshot` data.
/// It handles loading snapshots from `UserDefaults`, normalizing their state based on the current time, and formatting time-related strings for display.
enum WidgetSnapshotStore {
    /// Loads the `WidgetCycleSnapshot` from `UserDefaults`.
    /// - Returns: An optional `WidgetCycleSnapshot` if found and decoded successfully, otherwise `nil`.
    static func load() -> WidgetCycleSnapshot? {
        let defaults = UserDefaults(suiteName: WidgetConstants.appGroupIdentifier) ?? .standard
        guard let data = defaults.data(forKey: WidgetConstants.snapshotDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetCycleSnapshot.self, from: data)
    }

    /// Calculates the remaining time for a given `WidgetCycleSnapshot`.
    /// - Parameters:
    ///   - snapshot: The `WidgetCycleSnapshot` to calculate remaining time for.
    ///   - now: The current date, defaults to `.now`.
    /// - Returns: The remaining time interval in seconds.
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

    /// Normalizes the `WidgetCycleSnapshot` by updating its status to `.completed` if the scheduled end date has passed.
    /// - Parameters:
    ///   - snapshot: The `WidgetCycleSnapshot` to normalize.
    ///   - now: The current date, defaults to `.now`.
    /// - Returns: The normalized `WidgetCycleSnapshot`.
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

    /// Formats a `TimeInterval` into a human-readable duration string (MM:SS).
    /// - Parameter seconds: The time interval in seconds.
    /// - Returns: A string representing the duration.
    static func durationString(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds.rounded()), 0)
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    /// Formats an elapsed time interval since a given date into a human-readable string (e.g., "5m ago", "2h ago").
    /// - Parameters:
    ///   - date: The reference date.
    ///   - now: The current date, defaults to `.now`.
    /// - Returns: A string representing the elapsed time.
    static func elapsedString(since date: Date, now: Date = .now) -> String {
        let elapsed = max(now.timeIntervalSince(date), 0)

        if elapsed < 60 {
            return "just now"
        }

        let minutes = Int(elapsed / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        let hours = Int(elapsed / 3600)
        if hours < 24 {
            return "\(hours)h ago"
        }

        let days = Int(elapsed / 86_400)
        return "\(days)d ago"
    }

    /// Formats an elapsed time interval since a given date into a compact human-readable string (e.g., "now", "5m ago").
    /// - Parameters:
    ///   - date: The reference date.
    ///   - now: The current date, defaults to `.now`.
    /// - Returns: A compact string representing the elapsed time.
    static func compactElapsedString(since date: Date, now: Date = .now) -> String {
        let elapsed = max(now.timeIntervalSince(date), 0)

        if elapsed < 60 {
            return "now"
        }

        let minutes = Int(elapsed / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        let hours = Int(elapsed / 3600)
        if hours < 24 {
            return "\(hours)h ago"
        }

        let days = Int(elapsed / 86_400)
        return "\(days)d ago"
    }
}
