import SwiftUI

/// Provides quick-start cards, a custom time sheet, and recent presets on the home surface.
struct HomeView: View {
    @ObservedObject var coordinator: CycleCoordinator
    @State private var showingCustomDuration = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.sectionSpacing) {
                heroSection
                readyBanner
                quickActionSection
                customDurationButton
                if !coordinator.recentPresets.isEmpty {
                    recentPresetsSection
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(DesignTokens.pageBackground.ignoresSafeArea())
        .sheet(isPresented: $showingCustomDuration) {
            CustomDurationSheet(coordinator: coordinator)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Laundry Loop")
                .font(.title3.weight(.bold))
            Text("Start a cycle in under 5 seconds.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(DesignTokens.heroPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.cardMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
    }

    private var readyBanner: some View {
        HStack {
            Label("Ready", systemImage: "bolt.circle")
                .font(.caption.weight(.semibold))
            Spacer()
            Text(coordinator.snapshot == nil ? "Idle" : "Cycle active")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: DesignTokens.bannerHeight)
        .background(DesignTokens.bannerMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
    }

    private var quickActionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick starts")
                .font(.caption)
                .foregroundStyle(.secondary)
            quickStartCard(kind: .washer, badge: "Fast")
            quickStartCard(kind: .dryer, badge: "Warm")
        }
    }

    private func quickStartCard(kind: CycleKind, badge: String) -> some View {
        Button {
            Task { await coordinator.startDefaultCycle(kind: kind) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label(kind.title, systemImage: kind == .washer ? "washer" : "wind")
                            .font(.headline)
                        Spacer()
                        Text(badge)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignTokens.badgeMaterial, in: Capsule())
                    }
                    Text("\(kind == .washer ? coordinator.settings.defaultWasherMinutes : coordinator.settings.defaultDryerMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(DesignTokens.gradient(for: kind), in: RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(kind == .washer ? "start-washer-button" : "start-dryer-button")
        .accessibilityHint("Starts a \(kind.title.lowercased()) cycle")
    }

    private var customDurationButton: some View {
        Button {
            showingCustomDuration = true
        } label: {
            Label("Custom Time", systemImage: "timer")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Choose your own duration")
    }

    private var recentPresetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Presets")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(coordinator.recentPresets) { preset in
                Button {
                    Task { await coordinator.startCycle(kind: preset.kind, minutes: preset.durationMinutes) }
                } label: {
                    HStack {
                        Image(systemName: preset.kind == .washer ? "washer" : "dryer")
                        Text(preset.title)
                        Spacer()
                        Text(DurationFormatter.shortLabel(minutes: preset.durationMinutes))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    HomeView(coordinator: PreviewSupport.makeCoordinator())
}
