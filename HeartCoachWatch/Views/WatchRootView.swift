import SwiftUI

struct WatchRootView: View {
    @Environment(WorkoutWatchViewModel.self) private var viewModel
    /// Default to the metrics page; the controls page sits to its left (swipe right).
    @State private var page = 1

    var body: some View {
        if viewModel.isWorkoutActive {
            TabView(selection: $page) {
                WatchControlsView().tag(0)
                WorkoutWatchView().tag(1)
            }
            .tabViewStyle(.page)
            // Always return to the metrics page when a new workout starts.
            .onChange(of: viewModel.isWorkoutActive) { _, active in if active { page = 1 } }
        } else {
            IdleWatchView()
        }
    }
}
