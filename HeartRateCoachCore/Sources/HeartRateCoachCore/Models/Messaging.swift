import Foundation

/// Command sent from iPhone CoachingEngine to Apple Watch via WatchConnectivity.
public enum CoachingCommand: Sendable {
    /// Execute a haptic pattern on the Watch.
    case haptic(HapticPattern)
    /// Display a zone transition overlay with the given text for 3 seconds.
    case showCoachingOverlay(String)
    /// Show full-screen emergency stop — HR exceeded HRmax.
    case emergencyStop
    /// Activate Watch workout display.
    case workoutStarted
    /// Deactivate Watch workout display.
    case workoutStopped
}

/// Lightweight HR data point in transit from Watch sensor to iPhone CoachingEngine.
/// Not persisted — used only during an active workout.
public struct HRReading: Sendable {
    /// Raw heart rate value in bpm.
    public let value: Int
    /// Wall-clock time the reading was taken.
    public let timestamp: Date

    public init(value: Int, timestamp: Date = Date()) {
        self.value = value
        self.timestamp = timestamp
    }
}
