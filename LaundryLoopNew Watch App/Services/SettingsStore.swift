import Foundation
import SwiftData

final class SettingsStore: SettingsStoring {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadSettings() throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettingsRecord>()
        if let record = try modelContext.fetch(descriptor).first {
            return AppSettings(
                defaultWasherMinutes: record.defaultWasherMinutes,
                defaultDryerMinutes: record.defaultDryerMinutes,
                reminderLeadMinutes: record.reminderLeadMinutes,
                hapticsEnabled: record.hapticsEnabled
            )
        }

        let record = AppSettingsRecord()
        modelContext.insert(record)
        try modelContext.save()
        return .default
    }

    func saveSettings(_ settings: AppSettings) throws {
        let descriptor = FetchDescriptor<AppSettingsRecord>()
        let record = try modelContext.fetch(descriptor).first ?? {
            let newRecord = AppSettingsRecord()
            modelContext.insert(newRecord)
            return newRecord
        }()

        record.defaultWasherMinutes = settings.defaultWasherMinutes
        record.defaultDryerMinutes = settings.defaultDryerMinutes
        record.reminderLeadMinutes = settings.reminderLeadMinutes
        record.hapticsEnabled = settings.hapticsEnabled
        try modelContext.save()
    }
}
