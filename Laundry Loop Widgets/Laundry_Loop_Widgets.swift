import SwiftUI
import WidgetKit

struct LaundryLoopEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetCycleSnapshot?
}

struct LaundryLoopProvider: TimelineProvider {
    func placeholder(in context: Context) -> LaundryLoopEntry {
        LaundryLoopEntry(date: .now, snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LaundryLoopEntry) -> Void) {
        completion(LaundryLoopEntry(date: .now, snapshot: WidgetSnapshotStore.load().map { WidgetSnapshotStore.normalized($0) }))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LaundryLoopEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshotStore.load().map { WidgetSnapshotStore.normalized($0, now: now) }
        completion(Timeline(entries: timelineEntries(for: snapshot, now: now), policy: .never))
    }

    private func timelineEntries(for snapshot: WidgetCycleSnapshot?, now: Date) -> [LaundryLoopEntry] {
        guard let snapshot else {
            return [LaundryLoopEntry(date: now, snapshot: nil)]
        }

        var entries = [LaundryLoopEntry(date: now, snapshot: snapshot)]

        if let endDate = snapshot.displayEndDate, endDate > now {
            entries.append(
                LaundryLoopEntry(
                    date: endDate,
                    snapshot: WidgetSnapshotStore.normalized(snapshot, now: endDate)
                )
            )
        }

        return entries
    }
}

/// Presents the timeline entry using a family-specific layout that reflects the active/idle state.
struct LaundryLoopWidgetView: View {
    var entry: LaundryLoopProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        widgetContent
            .widgetURL(widgetURL)
            .containerBackground(for: .widget) {
                WidgetContainerBackground(family: family)
            }
    }

    private var widgetURL: URL? {
        if entry.snapshot != nil {
            return URL(string: "laundryloop://active")
        } else {
            return URL(string: "laundryloop://home")
        }
    }

    @ViewBuilder
    private var widgetContent: some View {
        switch family {
        case .accessoryCircular:
            WidgetAccessoryCircularContent(snapshot: entry.snapshot)
        case .accessoryInline:
            WidgetAccessoryInlineContent(snapshot: entry.snapshot)
        default:
            WidgetAccessoryRectangularContent(snapshot: entry.snapshot)
        }
    }
}

/// Stateless widget configuration used by the Smart Stack and complications.
struct LaundryLoopWidget: Widget {
    let kind: String = "LaundryLoopCycleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LaundryLoopProvider()) { entry in
            LaundryLoopWidgetView(entry: entry)
        }
        .configurationDisplayName("Laundry Cycle")
        .description("Glance at the current laundry cycle on your wrist.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
        ])
    }
}

private extension LaundryLoopWidgetView {
    static func previewSnapshot(
        status: WidgetCycleStatus,
        kind: WidgetCycleKind = .washer
    ) -> WidgetCycleSnapshot {
        let now = Date()

        switch status {
        case .running:
            return WidgetCycleSnapshot(
                id: UUID(),
                kind: kind,
                status: .running,
                configuredDuration: 45 * 60,
                countdownDuration: 45 * 60,
                phaseStartedAt: now.addingTimeInterval(-25 * 60),
                scheduledEnd: now.addingTimeInterval(20 * 60),
                remainingWhenPaused: nil,
                lastModifiedAt: now,
                completedAt: nil,
                reminderLeadMinutes: 5
            )

        case .paused:
            return WidgetCycleSnapshot(
                id: UUID(),
                kind: kind,
                status: .paused,
                configuredDuration: 45 * 60,
                countdownDuration: 45 * 60,
                phaseStartedAt: now.addingTimeInterval(-25 * 60),
                scheduledEnd: nil,
                remainingWhenPaused: 12 * 60,
                lastModifiedAt: now,
                completedAt: nil,
                reminderLeadMinutes: 5
            )

        case .completed:
            return WidgetCycleSnapshot(
                id: UUID(),
                kind: kind,
                status: .completed,
                configuredDuration: 45 * 60,
                countdownDuration: 45 * 60,
                phaseStartedAt: now.addingTimeInterval(-45 * 60),
                scheduledEnd: nil,
                remainingWhenPaused: 0,
                lastModifiedAt: now,
                completedAt: now.addingTimeInterval(-60),
                reminderLeadMinutes: 5
            )

        case .snoozed:
            return WidgetCycleSnapshot(
                id: UUID(),
                kind: kind,
                status: .snoozed,
                configuredDuration: 5 * 60,
                countdownDuration: 5 * 60,
                phaseStartedAt: now,
                scheduledEnd: now.addingTimeInterval(5 * 60),
                remainingWhenPaused: nil,
                lastModifiedAt: now,
                completedAt: nil,
                reminderLeadMinutes: 0
            )

        case .idle:
            return WidgetCycleSnapshot(
                id: UUID(),
                kind: kind,
                status: .idle,
                configuredDuration: 0,
                countdownDuration: 0,
                phaseStartedAt: now,
                scheduledEnd: nil,
                remainingWhenPaused: nil,
                lastModifiedAt: now,
                completedAt: nil,
                reminderLeadMinutes: 0
            )
        }
    }
}

#Preview("Rectangular Running", as: .accessoryRectangular) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .running))
}

#Preview("Rectangular Paused", as: .accessoryRectangular) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .paused))
}

#Preview("Rectangular Completed", as: .accessoryRectangular) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .completed))
}

#Preview("Rectangular Snoozed", as: .accessoryRectangular) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .snoozed, kind: .dryer))
}

#Preview("Rectangular Idle", as: .accessoryRectangular) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: nil)
}

#Preview("Inline Running", as: .accessoryInline) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .running))
}

#Preview("Inline Paused", as: .accessoryInline) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .paused))
}

#Preview("Circular Running", as: .accessoryCircular) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .running))
}

#Preview("Circular Completed", as: .accessoryCircular) {
    LaundryLoopWidget()
} timeline: {
    LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot(status: .completed))
}
