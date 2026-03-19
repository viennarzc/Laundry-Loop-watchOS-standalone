import Foundation

struct ActiveCycleSnapshot: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    var kind: CycleKind
    var status: CycleStatus
    var configuredDuration: TimeInterval
    var countdownDuration: TimeInterval
    var phaseStartedAt: Date
    var scheduledEnd: Date?
    var remainingWhenPaused: TimeInterval?
    var lastModifiedAt: Date
    var completedAt: Date?
    var reminderLeadMinutes: Int

    var isActive: Bool {
        status == .running || status == .paused || status == .snoozed || status == .completed
    }

    var nextReminderAt: Date? {
        guard let end = scheduledEnd, reminderLeadMinutes > 0 else {
            return nil
        }
        return end.addingTimeInterval(-TimeInterval(reminderLeadMinutes * 60))
    }

    func completedElapsedString(now: Date = .now) -> String? {
        guard status == .completed, let completedAt else {
            return nil
        }
        return DurationFormatter.elapsedString(since: completedAt, now: now)
    }
}
