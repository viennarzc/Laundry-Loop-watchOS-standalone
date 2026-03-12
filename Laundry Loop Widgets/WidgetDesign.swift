import SwiftUI
import WidgetKit

enum WidgetDesign {
    static func tint(for kind: WidgetCycleKind) -> Color {
        kind == .washer ? Color.blue : Color.orange
    }
}

/// Declares the widget-owned background so WidgetKit can remove or adapt it in each context.
struct WidgetContainerBackground: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryRectangular:
            ContainerRelativeShape()
                .fill(.ultraThinMaterial)
        default:
            Color.clear
        }
    }
}

struct WidgetCycleHeader: View {
    let snapshot: WidgetCycleSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: snapshot.kind.symbolName)
                .font(.headline)
                .foregroundStyle(WidgetDesign.tint(for: snapshot.kind))
                .frame(width: 18, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.kind.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(snapshot.displayStateLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

struct WidgetPrimaryStatusValue: View {
    let snapshot: WidgetCycleSnapshot

    var body: some View {
        Group {
            switch snapshot.status {
            case .running, .snoozed:
                if let endDate = snapshot.displayEndDate {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Ends")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(endDate, style: .time)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                } else {
                    Text(snapshot.displayStateLine)
                        .font(.callout)
                        .fontWeight(.semibold)
                }

            case .paused:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(snapshot.displayRemainingString ?? "00:00")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

            case .completed:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Finished")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(snapshot.completedDisplayLabel)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

            case .idle:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Idle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("No active cycle")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Compact layout that exposes the current cycle state as stable glance data.
struct WidgetActiveContent: View {
    let snapshot: WidgetCycleSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetCycleHeader(snapshot: snapshot)
            WidgetPrimaryStatusValue(snapshot: snapshot)
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

/// Circular accessory family content, showing a stable icon and status value.
struct WidgetAccessoryCircularContent: View {
    let snapshot: WidgetCycleSnapshot?

    var body: some View {
        if let snapshot {
            circularContent(for: snapshot)
        } else {
            Image(systemName: "timer")
                .font(.title3)
        }
    }

    @ViewBuilder
    private func circularContent(for snapshot: WidgetCycleSnapshot) -> some View {
        switch snapshot.status {
        case .running, .snoozed:
            if let endDate = snapshot.displayEndDate {
                VStack(spacing: 2) {
                    Image(systemName: snapshot.kind.symbolName)
                        .font(.caption)
                        .foregroundStyle(WidgetDesign.tint(for: snapshot.kind))
                    Text(endDate, style: .time)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .multilineTextAlignment(.center)
            } else {
                Image(systemName: snapshot.kind.symbolName)
                    .font(.title3)
            }

        case .paused:
            VStack(spacing: 2) {
                Image(systemName: "pause.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot.displayRemainingString ?? "00:00")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .multilineTextAlignment(.center)

        case .completed:
            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(snapshot.completedCompactLabel)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .multilineTextAlignment(.center)

        case .idle:
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
    }
}

/// Inline accessory content that keeps the status text compact and stable.
struct WidgetAccessoryInlineContent: View {
    let snapshot: WidgetCycleSnapshot?

    var body: some View {
        Group {
            if let snapshot {
                inlineText(for: snapshot)
            } else {
                Text("No active cycle")
            }
        }
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private func inlineText(for snapshot: WidgetCycleSnapshot) -> Text {
        switch snapshot.status {
        case .running, .snoozed:
            if let endDate = snapshot.displayEndDate {
                return Text("\(snapshot.kind.title) ") + Text(endDate, style: .time)
            }
            return Text("\(snapshot.kind.title) \(snapshot.displayStateLine)")

        case .paused:
            if let remaining = snapshot.displayRemainingString {
                return Text("\(snapshot.kind.title) Paused \(remaining)")
            }
            return Text("\(snapshot.kind.title) Paused")

        case .completed:
            return Text("\(snapshot.kind.title) done ") + Text(snapshot.completedCompactLabel)

        case .idle:
            return Text("No active cycle")
        }
    }
}
