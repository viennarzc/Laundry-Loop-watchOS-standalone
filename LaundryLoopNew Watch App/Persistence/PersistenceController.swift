import Foundation
import SwiftData

enum PersistenceController {
    static let shared: ModelContainer = {
        do {
            let schema = Schema([
                AppSettingsRecord.self,
                RecentPresetRecord.self,
            ])
            if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) {
                let storeURL = groupURL.appendingPathComponent("LaundryLoop.store")
                let configuration = ModelConfiguration(schema: schema, url: storeURL)
                return try ModelContainer(for: schema, configurations: [configuration])
            }
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()

    static func inMemory() throws -> ModelContainer {
        let schema = Schema([
            AppSettingsRecord.self,
            RecentPresetRecord.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
