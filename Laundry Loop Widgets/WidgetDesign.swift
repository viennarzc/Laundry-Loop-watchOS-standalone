import SwiftUI
import WidgetKit

private let widgetReminderFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

enum WidgetDesign {
    static func tint(for kind: WidgetCycleKind) -> Color {
        kind == .washer ? Color.blue : Color.orange
    }
}

/// Visual ring that mirrors the active progress value across widget families.
struct WidgetProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

/// Compact layout that exposes the current cycle status, reminder, and remaining time.
struct WidgetActiveContent: View {
    let snapshot: WidgetCycleSnapshot

    var body: some View {
        let remaining = WidgetSnapshotStore.remaining(for: snapshot)
        VStack(alignment: .leading, spacing: 6) {
            Label(snapshot.kind.title, systemImage: snapshot.kind.symbolName)
                .font(.headline)
                .foregroundColor(.primary)
            Text(WidgetSnapshotStore.stateLine(for: snapshot))
                .font(.caption2)
                .foregroundStyle(.secondary)
            WidgetProgressRing(progress: WidgetSnapshotStore.progress(for: snapshot), color: WidgetDesign.tint(for: snapshot.kind))
                .frame(height: 30)
            HStack(alignment: .top) {
                Text(WidgetSnapshotStore.durationString(remaining))
                    .font(.callout)
                    .fontWeight(.semibold)
                Spacer()
                if let reminder = snapshot.nextReminderAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Reminder")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(widgetReminderFormatter.string(from: reminder))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
    }
}

/// Idle-state placeholder that encourages a new cycle.
struct WidgetIdleContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Laundry Loop", systemImage: "timer")
                .font(.headline)
            Text("No active cycle")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Start washer or dryer")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
    }
}

/// Circular accessory family content, showing just the progress ring.
struct WidgetAccessoryCircularContent: View {
    let snapshot: WidgetCycleSnapshot?

    var body: some View {
        if let snapshot {
            let progress = WidgetSnapshotStore.progress(for: snapshot)
            WidgetProgressRing(progress: progress, color: WidgetDesign.tint(for: snapshot.kind))
                .padding(4)
        } else {
            Image(systemName: "timer")
                .font(.title3)
        }
    }
}

/// Rectangular accessory content for the active widget (also used for previews).
struct WidgetAccessoryRectangularContent: View {
    let snapshot: WidgetCycleSnapshot?

    var body: some View {
        Group {
            if let snapshot {
                WidgetActiveContent(snapshot: snapshot)
            } else {
                WidgetIdleContent()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Inline accessory content that keeps the status text compact.
struct WidgetAccessoryInlineContent: View {
    let snapshot: WidgetCycleSnapshot?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "washer")
            if let snapshot {
                Text(WidgetSnapshotStore.stateLine(for: snapshot))
            } else {
                Text("Idle")
            }
        }
        .font(.caption2)
    }
}
