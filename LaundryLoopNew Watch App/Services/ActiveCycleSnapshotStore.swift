import Foundation

final class ActiveCycleSnapshotStore: SnapshotStoring {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults? = UserDefaults(suiteName: AppConstants.appGroupIdentifier)) {
        self.defaults = defaults ?? .standard
    }

    func load() -> ActiveCycleSnapshot? {
        guard let data = defaults.data(forKey: AppConstants.snapshotDefaultsKey) else {
            return nil
        }
        return try? decoder.decode(ActiveCycleSnapshot.self, from: data)
    }

    func save(_ snapshot: ActiveCycleSnapshot?) {
        guard let snapshot else {
            defaults.removeObject(forKey: AppConstants.snapshotDefaultsKey)
            return
        }
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: AppConstants.snapshotDefaultsKey)
        }
    }
}
