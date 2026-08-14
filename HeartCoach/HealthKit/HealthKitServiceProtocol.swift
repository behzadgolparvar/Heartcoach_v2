import Foundation

protocol HealthKitServiceProtocol: AnyObject {
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func fetchRestingHeartRate() async -> Int?
    /// Wakes the paired Apple Watch and launches the companion app into a workout
    /// session, so heart rate starts streaming without the user opening the Watch app.
    func startWatchWorkout()
}
