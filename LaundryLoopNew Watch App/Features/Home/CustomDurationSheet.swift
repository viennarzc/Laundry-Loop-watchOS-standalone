import SwiftUI

/// Lets people pick a cycle kind and duration before starting a custom timer.
struct CustomDurationSheet: View {
    @ObservedObject var coordinator: CycleCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var cycleKind: CycleKind = .washer
    @State private var durationMinutes = 45

    private let minuteOptions = [15, 30, 45, 60, 90]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Cycle", selection: $cycleKind) {
                    ForEach(CycleKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }

                Picker("Duration", selection: $durationMinutes) {
                    ForEach(minuteOptions, id: \.self) { minute in
                        Text("\(minute) minutes").tag(minute)
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
}

#Preview {
    CustomDurationSheet(coordinator: PreviewSupport.makeCoordinator())
}
