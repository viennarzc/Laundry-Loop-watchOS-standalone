import Foundation

struct RecentPreset: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: CycleKind
    let durationMinutes: Int
    let lastUsedAt: Date

    var title: String {
        "\(kind.title) \(durationMinutes)m"
    }
}
