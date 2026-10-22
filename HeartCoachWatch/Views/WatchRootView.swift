import SwiftUI

struct WatchRootView: View {
    @Environment(WorkoutWatchViewModel.self) private var viewModel
    /// Which workout page is shown: 0 = controls (swipe left), 1 = metrics. Default metrics.
    @State private var page = 1

    var body: some View {
        Group {
            if viewModel.isWorkoutActive {
                TabView(selection: $page) {
                    WatchControlsView().tag(0)
                    WorkoutWatchView().tag(1)
                }
                .tabViewStyle(.page)
            } else {
                IdleWatchView()
            }
        }
        // Snap to the metrics page around every workout so a new session always opens
        // on HR/metrics (never the controls page). This must sit on an always-present
        // view — inside the `if` it would be created only once active and miss the
        // start transition. Resetting on end leaves it ready for the next start (no flash).
        .onChange(of: viewModel.isWorkoutActive) { _, _ in page = 1 }
    }
}
