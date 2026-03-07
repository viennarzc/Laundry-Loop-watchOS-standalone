import Foundation

struct LaundryCycle: Identifiable, Equatable, Sendable {
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

    init(snapshot: ActiveCycleSnapshot) {
        id = snapshot.id
        kind = snapshot.kind
        status = snapshot.status
        configuredDuration = snapshot.configuredDuration
        countdownDuration = snapshot.countdownDuration
        phaseStartedAt = snapshot.phaseStartedAt
        scheduledEnd = snapshot.scheduledEnd
        remainingWhenPaused = snapshot.remainingWhenPaused
        lastModifiedAt = snapshot.lastModifiedAt
        completedAt = snapshot.completedAt
    }
}
