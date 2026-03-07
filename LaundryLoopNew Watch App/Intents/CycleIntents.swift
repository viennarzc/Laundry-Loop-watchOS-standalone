import AppIntents
import Foundation

struct StartWasherIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Washer"
    static var description = IntentDescription("Start the default washer cycle.")

    func perform() async throws -> some IntentResult {
        await AppEnvironment.makeCoordinator().startDefaultCycle(kind: .washer)
        return .result()
    }
}

struct StartDryerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Dryer"
    static var description = IntentDescription("Start the default dryer cycle.")

    func perform() async throws -> some IntentResult {
        await AppEnvironment.makeCoordinator().startDefaultCycle(kind: .dryer)
        return .result()
    }
}

struct StartCustomCycleIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Custom Cycle"

    @Parameter(title: "Cycle")
    var cycleKind: CycleKindEntity

    @Parameter(title: "Minutes")
    var minutes: Int

    func perform() async throws -> some IntentResult {
        await AppEnvironment.makeCoordinator().startCycle(kind: cycleKind.kind, minutes: max(minutes, 1))
        return .result()
    }
}

struct MarkLaundryDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Laundry Done"

    func perform() async throws -> some IntentResult {
        await AppEnvironment.makeCoordinator().markDone()
        return .result()
    }
}

struct SnoozeLaundryReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Laundry Reminder"

    func perform() async throws -> some IntentResult {
        await AppEnvironment.makeCoordinator().snoozeFiveMinutes()
        return .result()
    }
}

struct CycleKindEntity: AppEntity, Sendable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Cycle")
    static var defaultQuery = CycleKindQuery()

    let id: String
    let kind: CycleKind

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: kind.title))
    }

    init(kind: CycleKind) {
        self.id = kind.rawValue
        self.kind = kind
    }
}

struct CycleKindQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CycleKindEntity] {
        CycleKind.allCases.filter { identifiers.contains($0.rawValue) }.map(CycleKindEntity.init(kind:))
    }

    func suggestedEntities() async throws -> [CycleKindEntity] {
        CycleKind.allCases.map(CycleKindEntity.init(kind:))
    }
}
