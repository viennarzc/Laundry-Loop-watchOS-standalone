import Foundation

enum CycleTimerEngine {
    static func start(kind: CycleKind, minutes: Int, reminderLeadMinutes: Int = 5, now: Date = .now) -> ActiveCycleSnapshot {
        let duration = TimeInterval(minutes * 60)
        return ActiveCycleSnapshot(
            id: UUID(),
            kind: kind,
            status: .running,
            configuredDuration: duration,
            countdownDuration: duration,
            phaseStartedAt: now,
            scheduledEnd: now.addingTimeInterval(duration),
            remainingWhenPaused: nil,
            lastModifiedAt: now,
            completedAt: nil,
            reminderLeadMinutes: reminderLeadMinutes
        )
    }

    static func remainingTime(for snapshot: ActiveCycleSnapshot, now: Date = .now) -> TimeInterval {
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

    static func progress(for snapshot: ActiveCycleSnapshot, now: Date = .now) -> Double {
        guard snapshot.countdownDuration > 0 else { return 1 }
        let remaining = remainingTime(for: snapshot, now: now)
        let progress = 1 - (remaining / snapshot.countdownDuration)
        return min(max(progress, 0), 1)
    }

    static func normalize(_ snapshot: ActiveCycleSnapshot, now: Date = .now) -> ActiveCycleSnapshot {
        guard snapshot.status.isCountdownActive else { return snapshot }
        guard let scheduledEnd = snapshot.scheduledEnd, scheduledEnd <= now else { return snapshot }

        var completed = snapshot
        completed.status = .completed
        completed.completedAt = scheduledEnd
        completed.scheduledEnd = nil
        completed.remainingWhenPaused = 0
        completed.lastModifiedAt = now
        return completed
    }

    static func pause(_ snapshot: ActiveCycleSnapshot, now: Date = .now) -> ActiveCycleSnapshot {
        var paused = normalize(snapshot, now: now)
        let remaining = remainingTime(for: paused, now: now)
        paused.status = .paused
        paused.remainingWhenPaused = remaining
        paused.scheduledEnd = nil
        paused.lastModifiedAt = now
        return paused
    }

    static func resume(_ snapshot: ActiveCycleSnapshot, now: Date = .now) -> ActiveCycleSnapshot {
        var resumed = snapshot
        let remaining = max(snapshot.remainingWhenPaused ?? snapshot.countdownDuration, 0)
        resumed.status = .running
        resumed.phaseStartedAt = now
        resumed.scheduledEnd = now.addingTimeInterval(remaining)
        resumed.remainingWhenPaused = nil
        resumed.lastModifiedAt = now
        return resumed
    }

    static func addTime(_ snapshot: ActiveCycleSnapshot, minutes: Int, now: Date = .now) -> ActiveCycleSnapshot {
        let extra = TimeInterval(minutes * 60)
        var updated = normalize(snapshot, now: now)
        updated.configuredDuration += extra
        updated.countdownDuration += extra
        switch updated.status {
        case .paused:
            updated.remainingWhenPaused = (updated.remainingWhenPaused ?? 0) + extra
        case .running, .snoozed:
            let currentEnd = updated.scheduledEnd ?? now
            updated.scheduledEnd = currentEnd.addingTimeInterval(extra)
        case .completed, .idle:
            break
        }
        updated.lastModifiedAt = now
        return updated
    }

    static func snooze(_ snapshot: ActiveCycleSnapshot, minutes: Int, now: Date = .now) -> ActiveCycleSnapshot {
        let duration = TimeInterval(minutes * 60)
        var snoozed = snapshot
        snoozed.status = .snoozed
        snoozed.countdownDuration = duration
        snoozed.phaseStartedAt = now
        snoozed.scheduledEnd = now.addingTimeInterval(duration)
        snoozed.remainingWhenPaused = nil
        snoozed.completedAt = nil
        snoozed.lastModifiedAt = now
        return snoozed
    }

    static func restart(_ snapshot: ActiveCycleSnapshot, now: Date = .now) -> ActiveCycleSnapshot {
        let minutes = max(Int(snapshot.configuredDuration / 60), 1)
        return start(kind: snapshot.kind, minutes: minutes, reminderLeadMinutes: snapshot.reminderLeadMinutes, now: now)
    }
}
