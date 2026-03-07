import Foundation

enum CycleStatus: String, Codable, CaseIterable, Sendable {
    case idle
    case running
    case paused
    case completed
    case snoozed

    var isCountdownActive: Bool {
        self == .running || self == .snoozed
    }

    var title: String {
        switch self {
        case .idle: return "Idle"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .snoozed: return "Snoozed"
        }
    }
}
