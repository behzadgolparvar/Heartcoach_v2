import Foundation

/// Current workout state snapshot published to the UI every coaching tick.
/// Produced by CoachingEngine (Unit 3) and consumed by WorkoutViewModel.
public struct CoachingState: Sendable {
    /// Most recent raw HR reading from Watch sensor in bpm.
    public let currentHR: Int
    /// Smoothed HR — average of last 2 readings.
    public let hrSmooth: Int
    /// Zone the user is currently in (0 = below zones, 1–5 = in zone, 6 = above HRmax).
    public let currentZone: Int
    /// Zone required by the current phase. nil during recovery.
    public let targetZone: Int?
    /// Active phase type.
    public let phase: PhaseType
    /// Seconds remaining in the current phase.
    public let phaseTimeRemaining: TimeInterval
    /// Total elapsed workout time in seconds.
    public let elapsedTime: TimeInterval
    /// Active coaching message, if any (e.g. "Speed up", "Good job, keep going").
    public let coachingMessage: String?
    /// True during the first 10 seconds of a HIIT or Fartlek phase — coaching suppressed.
    public let isGracePeriodActive: Bool

    public init(currentHR: Int, hrSmooth: Int, currentZone: Int, targetZone: Int?,
                phase: PhaseType, phaseTimeRemaining: TimeInterval, elapsedTime: TimeInterval,
                coachingMessage: String? = nil, isGracePeriodActive: Bool = false) {
        self.currentHR = currentHR
        self.hrSmooth = hrSmooth
        self.currentZone = currentZone
        self.targetZone = targetZone
        self.phase = phase
        self.phaseTimeRemaining = phaseTimeRemaining
        self.elapsedTime = elapsedTime
        self.coachingMessage = coachingMessage
        self.isGracePeriodActive = isGracePeriodActive
    }
}
