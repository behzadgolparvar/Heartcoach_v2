import SwiftUI

struct WatchRootView: View {
    @Environment(WorkoutWatchViewModel.self) private var viewModel

    var body: some View {
        if viewModel.isWorkoutActive {
            WorkoutWatchView()
        } else {
            IdleWatchView()
        }
    }
}
