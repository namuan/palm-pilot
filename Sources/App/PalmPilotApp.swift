import SwiftUI

@main
struct PalmPilotApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            if viewModel.isTracking {
                Image(systemName: "hand.raised.fill")
            } else {
                Image(systemName: "hand.raised")
            }
        }

        WindowGroup("Settings", id: "settings") {
            SettingsView(viewModel: viewModel)
                .onAppear { viewModel.saveMappings() }
                .onDisappear { viewModel.saveMappings() }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 420)
    }
}
