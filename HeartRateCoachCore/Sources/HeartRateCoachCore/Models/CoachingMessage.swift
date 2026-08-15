import Foundation

/// A coaching output produced by CoachingEngine.tick() during a workout.
/// Carries spoken text for VoiceFeedbackService and an optional haptic pattern for WatchBridge.
public struct CoachingMessage: Sendable, Equatable {
    /// Layer that produced this message: 1 = Safety, 2 = Zone Coaching, 3 = Positive Feedback.
    public let layer: Int
    /// Text spoken aloud by AVSpeechSynthesizer.
    public let text: String
    /// Haptic pattern to send to Apple Watch. nil for messages with no corresponding haptic.
    public let hapticPattern: HapticPattern?

    public init(layer: Int, text: String, hapticPattern: HapticPattern? = nil) {
        self.layer = layer
        self.text = text
        self.hapticPattern = hapticPattern
    }
}

// MARK: - Factory Methods

public extension CoachingMessage {

    // MARK: Layer 1 — Safety

    /// HR exceeded HRmax — immediate stop required.
    static let emergencyStop = CoachingMessage(
        layer: 1,
        text: "Your heart rate is dangerously high. Stop immediately.",
        hapticPattern: .emergencyRepeated
    )

    /// HR is very high but below hard HRmax — urgent slow-down.
    static let criticalSlowDown = CoachingMessage(
        layer: 1,
        text: "Heart rate too high. Slow down now.",
        hapticPattern: .long
    )

    /// No HR signal received for 15 or more seconds.
    static let noSignal = CoachingMessage(
        layer: 1,
        text: "No heart rate signal. Please check your Watch.",
        hapticPattern: nil
    )

    // MARK: Layer 2 — Zone Coaching

    /// HR is below the target zone — user needs to push harder.
    static let speedUp = CoachingMessage(
        layer: 2,
        text: "Speed up — your heart rate is too low.",
        hapticPattern: .short
    )

    /// HR is above the target zone — user needs to back off.
    static let slowDown = CoachingMessage(
        layer: 2,
        text: "Slow down — your heart rate is too high.",
        hapticPattern: .long
    )

    // MARK: Layer 3 — Positive Feedback

    /// User has maintained target zone for 30 consecutive seconds.
    static let keepItUp = CoachingMessage(
        layer: 3,
        text: "Great work — keep it up!",
        hapticPattern: .doubleTap
    )

    /// Spoken once at the end of the start countdown, as the workout begins.
    static let letsGo = CoachingMessage(
        layer: 3,
        text: "Let's go!",
        hapticPattern: nil
    )
}
