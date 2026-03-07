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
        let snapshot = WidgetSnapshotStore.load().map { WidgetSnapshotStore.normalized($0) }
        var entries = [LaundryLoopEntry(date: now, snapshot: snapshot)]
        if snapshot != nil {
            entries.append(LaundryLoopEntry(date: now.addingTimeInterval(30), snapshot: nil))
        }
        let refresh = WidgetSnapshotStore.refreshInterval(for: snapshot, now: now)
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(refresh))))
    }
}

/// Presents the timeline entry using a family-specific layout that reflects the active/idle state.
struct LaundryLoopWidgetView: View {
    var entry: LaundryLoopProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            WidgetAccessoryCircularContent(snapshot: entry.snapshot)
                .widgetURL(widgetURL)
        case .accessoryInline:
            WidgetAccessoryInlineContent(snapshot: entry.snapshot)
                .widgetURL(widgetURL)
        default:
            WidgetAccessoryRectangularContent(snapshot: entry.snapshot)
                .widgetURL(widgetURL)
        }
    }

    private var widgetURL: URL? {
        if entry.snapshot != nil {
            return URL(string: "laundryloop://active")
        } else {
            return URL(string: "laundryloop://home")
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
    static func previewSnapshot() -> WidgetCycleSnapshot {
        WidgetCycleSnapshot(
            id: UUID(),
            kind: .washer,
            status: .running,
            configuredDuration: 45 * 60,
            countdownDuration: 20 * 60,
            phaseStartedAt: Date().addingTimeInterval(-600),
            scheduledEnd: Date().addingTimeInterval(20 * 60),
            remainingWhenPaused: nil,
            lastModifiedAt: Date(),
            completedAt: nil,
            reminderLeadMinutes: 5
        )
    }
}

#Preview("Widget active") {
    LaundryLoopWidgetView(entry: LaundryLoopEntry(date: .now, snapshot: LaundryLoopWidgetView.previewSnapshot()))
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
}

#Preview("Widget idle") {
    LaundryLoopWidgetView(entry: LaundryLoopEntry(date: .now, snapshot: nil))
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
}
