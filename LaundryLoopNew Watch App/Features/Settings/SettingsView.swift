import SwiftUI
import UserNotifications

/// Configures defaults for durations, reminders, and the haptic + notification experience.
struct SettingsView: View {
    @ObservedObject var coordinator: CycleCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.sectionSpacing) {
                durationSection
                reminderSection
                experienceSection
                notificationSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(DesignTokens.pageBackground.ignoresSafeArea())
        .navigationTitle("Settings")
    }

    private var durationSection: some View {
        settingsGroup(title: "Durations") {
            settingStepperRow(
                title: "Washer default",
                value: "\(coordinator.settings.defaultWasherMinutes) min",
                keyPath: \.defaultWasherMinutes,
                range: 15...120,
                step: 5
            )
            settingStepperRow(
                title: "Dryer default",
                value: "\(coordinator.settings.defaultDryerMinutes) min",
                keyPath: \.defaultDryerMinutes,
                range: 15...120,
                step: 5
            )
        }
    }

    private var reminderSection: some View {
        settingsGroup(title: "Reminders") {
            let reminderValue = coordinator.settings.reminderLeadMinutes == 0
                ? "Off"
                : "\(coordinator.settings.reminderLeadMinutes) min"

            settingStepperRow(
                title: "Reminder lead",
                value: reminderValue,
                keyPath: \.reminderLeadMinutes,
                range: 0...15,
                step: 5
            )
        }
    }

    private var experienceSection: some View {
        settingsGroup(title: "Experience") {
            settingToggleRow(title: "Haptics", keyPath: \.hapticsEnabled)
        }
    }

    private var notificationSection: some View {
        settingsGroup(title: "Notifications") {
            Text(notificationCopy)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func settingStepperRow(
        title: String,
        value: String,
        keyPath: WritableKeyPath<AppSettings, Int>,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        HStack(spacing: DesignTokens.controlSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
            Stepper("", value: binding(keyPath), in: range, step: step)
                .labelsHidden()
                .controlSize(.mini)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingToggleRow(title: String, keyPath: WritableKeyPath<AppSettings, Bool>) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Toggle("", isOn: binding(keyPath))
                .labelsHidden()
                .accessibilityLabel(Text(title))
                .toggleStyle(.switch)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var notificationCopy: String {
        switch coordinator.notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled. Laundry Loop will nudge you when a cycle is nearly done or finished."
        case .denied:
            return "Notifications are turned off for Laundry Loop. Enable them in Apple Watch settings if you want completion reminders."
        case .notDetermined:
            return "Laundry Loop will ask for notification access when you start a cycle."
        @unknown default:
            return "Notification status is unavailable."
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { coordinator.settings[keyPath: keyPath] },
            set: { newValue in
                var updated = coordinator.settings
                updated[keyPath: keyPath] = newValue
                Task { await coordinator.updateSettings(updated) }
            }
        )
    }
}

#Preview {
    SettingsView(coordinator: PreviewSupport.makeCoordinator())
}
