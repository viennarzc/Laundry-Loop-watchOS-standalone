import Foundation

enum ReminderProfile: String, CaseIterable, Identifiable, Sendable {
    case gentle
    case standard
    case persistent

    var id: Self { self }

    var title: String {
        switch self {
        case .gentle: "Gentle"
        case .standard: "Standard"
        case .persistent: "Persistent"
        }
    }

    var explanation: String {
        switch self {
        case .gentle: "Completion alert only."
        case .standard: "Before finishing, at completion, and 15 minutes later."
        case .persistent: "Before finishing, at completion, and 15, 45, and 105 minutes later."
        }
    }

    var includesPrefinish: Bool { self != .gentle }

    var overdueOffsets: [TimeInterval] {
        switch self {
        case .gentle: []
        case .standard: [15 * 60]
        case .persistent: [15 * 60, 45 * 60, 105 * 60]
        }
    }
}
