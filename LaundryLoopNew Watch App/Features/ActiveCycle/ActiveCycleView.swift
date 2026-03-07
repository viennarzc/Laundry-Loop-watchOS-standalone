import SwiftUI

/// Displays the active laundry cycle with remaining time, progress, and quick actions.
struct ActiveCycleView: View {
    @ObservedObject var coordinator: CycleCoordinator
    let snapshot: ActiveCycleSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let normalized = CycleTimerEngine.normalize(snapshot, now: context.date)
            let remaining = CycleTimerEngine.remainingTime(for: normalized, now: context.date)
            let progress = CycleTimerEngine.progress(for: normalized, now: context.date)
            let elapsed = max(context.date.timeIntervalSince(normalized.phaseStartedAt), 0)
            let nextReminder = normalized.nextReminderAt

            ScrollView {
                VStack(spacing: DesignTokens.sectionSpacing) {
                    heroCard(for: normalized, remaining: remaining, progress: progress)
                    infoRow(nextReminder: nextReminder, elapsed: elapsed, total: normalized.configuredDuration)
                    actionSection(for: normalized)
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
            .task(id: normalized.status) {
                await coordinator.refreshTimerState()
            }
        }
    }

    private func heroCard(for snapshot: ActiveCycleSnapshot, remaining: TimeInterval, progress: Double) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text(snapshot.kind.title)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(coordinator.statusLine(for: snapshot))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progressNormalized(progress: progress))
                    .stroke(DesignTokens.tint(for: snapshot.kind), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text(DurationFormatter.minutesString(seconds: remaining))
                        .font(.system(.largeTitle, design: .rounded).monospacedDigit())
                        .fontWeight(.semibold)
                    Text("Time remaining")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
        }
        .padding(DesignTokens.heroPadding)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                DesignTokens.gradient(for: snapshot.kind)
                    .opacity(0.4)
                RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
    }

    private func infoRow(nextReminder: Date?, elapsed: TimeInterval, total: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.infoSpacing) {
            if let reminder = nextReminder {
                infoItem(
                    title: "Next reminder",
                    value: DurationFormatter.clockString(for: reminder)
                )
            }

            infoItem(
                title: "Elapsed",
                value: DurationFormatter.minutesString(seconds: elapsed)
            )

            infoItem(
                title: "Total",
                value: DurationFormatter.minutesString(seconds: total)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
    }

    private func infoItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionSection(for snapshot: ActiveCycleSnapshot) -> some View {
        VStack(spacing: 12) {
            if snapshot.status == .completed {
                completedActions
            } else {
                runningActions
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.cardMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
    }

    private var runningActions: some View {
        VStack(spacing: 10) {
            Button("+5 min") {
                Task { await coordinator.addFiveMinutes() }
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("add-five-button")

            Button(snapshot.status == .paused ? "Resume" : "Pause") {
                Task { await coordinator.pauseOrResume() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("pause-resume-button")

            Button("Done") {
                Task { await coordinator.markDone() }
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("done-button")

            Button("Restart") {
                Task { await coordinator.restartCycle() }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("restart-button")
        }
    }

    private var completedActions: some View {
        VStack(spacing: 10) {
            Button("Start Dryer") {
                Task { await coordinator.startDefaultCycle(kind: .dryer) }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .accessibilityIdentifier("start-dryer-complete-button")

            Button("Snooze 5 min") {
                Task { await coordinator.snoozeFiveMinutes() }
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("snooze-button")

            Button("Done") {
                Task { await coordinator.markDone() }
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("done-button")
        }
    }

    private func progressNormalized(progress: Double) -> CGFloat {
        CGFloat(max(min(progress, 1), 0))
    }
}

#Preview("Active running") {
    ActiveCycleView(coordinator: PreviewSupport.makeCoordinator(), snapshot: PreviewSupport.runningSnapshot)
}

#Preview("Active completed") {
    ActiveCycleView(coordinator: PreviewSupport.makeCoordinator(), snapshot: PreviewSupport.completedSnapshot)
}
