import SwiftUI

/// Lets people pick a cycle kind and duration before starting a custom timer.
struct CustomDurationSheet: View {
    @ObservedObject var coordinator: CycleCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var cycleKind: CycleKind
    @State private var durationMinutes: Int

    private let minuteOptions = Array(AppConstants.durationMinutesRange)
    private let pickerHeight: CGFloat = 92
    private let pickerHorizontalInset: CGFloat = 22
    private let pickerVerticalInset: CGFloat = 6

    init(coordinator: CycleCoordinator) {
        self.coordinator = coordinator
        _cycleKind = State(initialValue: .washer)
        _durationMinutes = State(initialValue: coordinator.settings.defaultWasherMinutes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    pickerCard(title: "Cycle") {
                        Picker("Cycle", selection: $cycleKind) {
                            ForEach(CycleKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.wheel)
                        .frame(height: pickerHeight)
                        .padding(.vertical, pickerVerticalInset)
                        .clipped()
                        .onChange(of: cycleKind) { newKind in
                            durationMinutes = defaultMinutes(for: newKind)
                        }
                    }

                    pickerCard(title: "Duration") {
                        Picker("Duration", selection: $durationMinutes) {
                            ForEach(minuteOptions, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.wheel)
                        .frame(height: pickerHeight)
                        .padding(.vertical, pickerVerticalInset)
                        .clipped()
                    }

                    Button("Start") {
                        Task {
                            await coordinator.startCycle(kind: cycleKind, minutes: durationMinutes)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .navigationTitle("Custom Time")
        }
    }

    @ViewBuilder
    private func pickerCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            content()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, pickerHorizontalInset)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
        }
    }

    private func defaultMinutes(for kind: CycleKind) -> Int {
        switch kind {
        case .washer:
            return coordinator.settings.defaultWasherMinutes
        case .dryer:
            return coordinator.settings.defaultDryerMinutes
        }
    }
}

#Preview {
    CustomDurationSheet(coordinator: PreviewSupport.makeCoordinator())
}
