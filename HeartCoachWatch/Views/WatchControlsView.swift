import SwiftUI

/// Swipe-left controls page (like Apple's Workout app): Pause/Resume + End.
/// Actions are sent to the phone, which drives the workout.
struct WatchControlsView: View {
    @Environment(WorkoutWatchViewModel.self) private var viewModel
    @State private var confirmEnd = false

    var body: some View {
        VStack(spacing: 10) {
            Button {
                // Optimistic toggle; the phone confirms via a "paused" message.
                let action = viewModel.isPaused ? "resume" : "pause"
                viewModel.isPaused.toggle()
                viewModel.onControl?(action)
            } label: {
                Label(viewModel.isPaused ? "Resume" : "Pause",
                      systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                    .font(.title3).frame(maxWidth: .infinity)
            }
            .tint(viewModel.isPaused ? .green : .orange)

            Button(role: .destructive) { confirmEnd = true } label: {
                Label("End", systemImage: "stop.fill")
                    .font(.title3).frame(maxWidth: .infinity)
            }
            .tint(.red)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 6)
        .confirmationDialog("End workout?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End Workout", role: .destructive) { viewModel.onControl?("end") }
            Button("Cancel", role: .cancel) {}
        }
    }
}
