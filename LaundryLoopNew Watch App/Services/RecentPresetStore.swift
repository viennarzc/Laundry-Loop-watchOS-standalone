import Foundation
import SwiftData

final class RecentPresetStore: RecentPresetStoring {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadRecentPresets() throws -> [RecentPreset] {
        var descriptor = FetchDescriptor<RecentPresetRecord>(sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)])
        descriptor.fetchLimit = AppConstants.maxRecentPresets
        return try modelContext.fetch(descriptor).compactMap { record in
            guard let kind = CycleKind(rawValue: record.kindRawValue) else { return nil }
            return RecentPreset(
                id: record.id,
                kind: kind,
                durationMinutes: record.durationMinutes,
                lastUsedAt: record.lastUsedAt
            )
        }
    }

    func remember(kind: CycleKind, durationMinutes: Int, usedAt: Date) throws {
        let descriptor = FetchDescriptor<RecentPresetRecord>()
        let records = try modelContext.fetch(descriptor)

        if let existing = records.first(where: { $0.kindRawValue == kind.rawValue && $0.durationMinutes == durationMinutes }) {
            existing.lastUsedAt = usedAt
        } else {
            modelContext.insert(RecentPresetRecord(kind: kind, durationMinutes: durationMinutes, lastUsedAt: usedAt))
        }

        try modelContext.save()

        var sortedDescriptor = FetchDescriptor<RecentPresetRecord>(sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)])
        let allRecords = try modelContext.fetch(sortedDescriptor)
        if allRecords.count > AppConstants.maxRecentPresets {
            allRecords.dropFirst(AppConstants.maxRecentPresets).forEach(modelContext.delete)
            try modelContext.save()
        }
    }
}
