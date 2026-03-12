import SwiftUI

@MainActor
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var coordinator: CycleCoordinator

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = coordinator.snapshot {
                    ActiveCycleView(coordinator: coordinator, snapshot: snapshot)
                } else {
                    HomeView(coordinator: coordinator)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(coordinator: coordinator)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .task {
            await coordinator.refreshFromPersistence()
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await coordinator.refreshFromPersistence()
        }
    }
}

#Preview {
    ContentView(coordinator: PreviewSupport.makeCoordinator())
}
