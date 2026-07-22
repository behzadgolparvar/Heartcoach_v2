import Foundation

/// All mutable state the coaching engine reads and writes between ticks.
/// Value type — owned and persisted by WorkoutSessionManager.
/// Passed as `inout` into CoachingEngine.tick() each 5-second tick.
public struct CoachingEngineState: Sendable {

    /// Last 2 raw HR readings from Watch sensor. Used to compute hrSmooth.
    public var hrBuffer: [Int]

    /// Timestamp of the most recent Layer 2 coaching message.
    /// nil = no message sent yet; used to enforce the 20-second anti-spam gap.
    public var lastLayer2MessageAt: Date?

    /// Seconds the user has continuously been inside their target zone.
    /// Reset to 0 on any out-of-zone tick, on pause, and when Layer 1 fires.
    /// Layer 3 fires at ≥30 seconds.
    public var consecutiveInZoneSeconds: TimeInterval

    public init(
        hrBuffer: [Int] = [],
        lastLayer2MessageAt: Date? = nil,
        consecutiveInZoneSeconds: TimeInterval = 0
    ) {
        self.hrBuffer = hrBuffer
        self.lastLayer2MessageAt = lastLayer2MessageAt
        self.consecutiveInZoneSeconds = consecutiveInZoneSeconds
    }

    /// Ceiling-rounded average of the last two HR readings.
    /// Returns 0 if the buffer is empty (before first HR reading arrives).
    public var hrSmooth: Int {
        guard !hrBuffer.isEmpty else { return 0 }
        return Int(ceil(Double(hrBuffer.reduce(0, +)) / Double(hrBuffer.count)))
    }

    /// Called on pause: resets the in-zone streak and clears anti-spam
    /// so coaching resumes promptly when the user resumes.
    public mutating func resetForPause() {
        consecutiveInZoneSeconds = 0
        lastLayer2MessageAt = nil
    }
}
