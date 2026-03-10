import SwiftUI

/// Lets people pick a cycle kind and duration before starting a custom timer.
struct CustomDurationSheet: View {
    @ObservedObject var coordinator: CycleCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var cycleKind: CycleKind
    @State private var durationMinutes: Int

    private let minuteOptions = Array(stride(from: 15, through: 120, by: 5))

    init(coordinator: CycleCoordinator) {
        self.coordinator = coordinator
        _cycleKind = State(initialValue: .washer)
        _durationMinutes = State(initialValue: coordinator.settings.defaultWasherMinutes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Cycle", selection: $cycleKind) {
                    ForEach(CycleKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .onChange(of: cycleKind) { newKind in
                    durationMinutes = defaultMinutes(for: newKind)
                }

                Picker("Duration", selection: $durationMinutes) {
                    ForEach(minuteOptions, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
            }
            .navigationTitle("Custom Time")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        Task {
                            await coordinator.startCycle(kind: cycleKind, minutes: durationMinutes)
                            dismiss()
                        }
                    }
                }
            }
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
