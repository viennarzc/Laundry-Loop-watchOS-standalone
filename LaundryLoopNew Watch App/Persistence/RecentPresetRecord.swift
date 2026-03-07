import Foundation
import SwiftData

@Model
final class RecentPresetRecord {
    var id: UUID
    var kindRawValue: String
    var durationMinutes: Int
    var lastUsedAt: Date

    init(id: UUID = UUID(), kind: CycleKind, durationMinutes: Int, lastUsedAt: Date = .now) {
        self.id = id
        self.kindRawValue = kind.rawValue
        self.durationMinutes = durationMinutes
        self.lastUsedAt = lastUsedAt
    }
}
