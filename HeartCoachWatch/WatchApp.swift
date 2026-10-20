import SwiftUI
import HealthKit

@main
struct WatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @State private var viewModel = WorkoutWatchViewModel()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(viewModel)
                .onAppear {
                    WatchSessionManager.shared.activate(viewModel: viewModel)
                }
        }
    }
}

/// Receives the workout the phone launches via `HKHealthStore.startWatchApp(with:)`.
/// Adopting it here (rather than starting a separate session) ties our session to the
/// system's workout launch, so when we end it watchOS releases the workout assertion
/// (otherwise the app lingers in the background with the face indicator stuck on).
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        WatchSessionManager.shared.beginWorkout(with: workoutConfiguration)
    }
}
