import Foundation

enum CycleKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case washer
    case dryer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .washer: return "Washer"
        case .dryer: return "Dryer"
        }
    }

    var iconName: String {
        switch self {
        case .washer: return "washer"
        case .dryer: return "dryer"
        }
    }

    var tintName: String {
        switch self {
        case .washer: return "blue"
        case .dryer: return "orange"
        }
    }
}
