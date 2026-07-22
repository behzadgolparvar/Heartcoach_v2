import SwiftUI

@main
struct WatchApp: App {
    @State private var sessionManager = WatchSessionManager()
    @State private var viewModel = WorkoutWatchViewModel()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(viewModel)
                .onAppear {
                    sessionManager.activate(viewModel: viewModel)
                }
        }
    }
}
