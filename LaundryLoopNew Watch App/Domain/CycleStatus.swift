import Foundation

enum CycleStatus: String, Codable, CaseIterable, Sendable {
    case idle
    case running
    case paused
    case completed
    case overdue
    case snoozed

    var isCountdownActive: Bool {
        self == .running || self == .snoozed
    }

    var isAwaitingAction: Bool { self == .completed || self == .overdue }

    var title: String {
        switch self {
        case .idle: return "Idle"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        case .snoozed: return "Snoozed"
        }
    }
}
