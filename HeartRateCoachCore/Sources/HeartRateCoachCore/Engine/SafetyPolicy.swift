import Foundation

/// Pure constants + decisions for the §J safety/edge flows. Device timers live in
/// the app; these are the testable rules.
public enum SafetyPolicy {
    /// No HR reading for this long → sensor-dropout state (BR-2-24).
    public static let sensorDropoutSec = 20
    /// Minutes paused before the resume prompt appears (BR-2-25).
    public static let pausePromptMinutes = 15
    /// Each "Need more time" snooze length.
    public static let pauseSnoozeMinutes = 10
    /// Max snoozes before the prompt stops offering "more time".
    public static let maxPauseSnoozes = 3

    public static func canSnooze(usedSnoozes: Int) -> Bool { usedSnoozes < maxPauseSnoozes }

    /// Elevated starting HR (§J): a resting check that triggers the walk_fallback path
    /// when the user begins already well above a calm baseline. Threshold = 40% of HRR
    /// above resting (≈ low Zone 2) — not at rest.
    public static func isElevatedStartHR(hr: Int, restingHR: Int, maxHR: Int) -> Bool {
        guard maxHR > restingHR else { return false }
        let threshold = Double(restingHR) + 0.40 * Double(maxHR - restingHR)
        return Double(hr) > threshold
    }
}
