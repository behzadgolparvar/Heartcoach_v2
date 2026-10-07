import Foundation

/// A single HR data point within a session's time-series.
public struct HRRecord: Codable, Sendable {
    public let timestamp: Date
    /// Elapsed seconds since workout start.
    public let second: Int
    /// Raw HR reading from Watch sensor in bpm.
    public let hr: Int
    /// Zone the user is currently in (1–5, or 0 if below Zone 1, 6 if above HRmax).
    public let currentZone: Int
    /// Zone the program requires at this moment. nil during recovery phases.
    public let targetZone: Int?
    /// Active phase type at this moment (v1 coarse type, kept for back-compat).
    public let phase: PhaseType
    /// v2 fine-grained phase segment (nil for v1 sessions). Drives export/scoring fidelity.
    public let phaseKind: PhaseKind?
    /// Coaching message delivered at this moment, if any.
    public let coachingMessage: String?

    public init(timestamp: Date, second: Int, hr: Int, currentZone: Int,
                targetZone: Int?, phase: PhaseType, phaseKind: PhaseKind? = nil,
                coachingMessage: String? = nil) {
        self.timestamp = timestamp
        self.second = second
        self.hr = hr
        self.currentZone = currentZone
        self.targetZone = targetZone
        self.phase = phase
        self.phaseKind = phaseKind
        self.coachingMessage = coachingMessage
    }
}

/// Immutable record of a completed workout session.
public struct Session: Codable, Sendable {
    /// Auto-generated UUID string.
    public let id: String
    /// Workout start timestamp.
    public let date: Date
    /// Which program was run.
    public let programType: WorkoutType
    /// Total duration in seconds.
    public let durationSec: Int
    /// Simple mean of all HR readings. 0 if no readings were collected.
    public let avgHR: Int
    /// Zone number (1–5) → seconds spent in that zone.
    public let timeInZones: [Int: Int]
    /// Full HR time-series recorded every 5 seconds during the workout.
    public let hrStream: [HRRecord]

    // v2 scoring (spec §D/FR-6) — nil for v1 sessions.
    /// % of scored training time spent in the per-block target.
    public let scorePercent: Double?
    public let scoreTier: ScoreTier?
    /// Training-only duration (excludes buffer/transition/cooldown).
    public let trainingDurationSec: Int?
    /// Persisted session flag: continuous | hiit | walk_fallback.
    public let sessionFlag: String?
    /// True when the user skipped/abandoned the mandatory cooldown.
    public let cooldownSkipped: Bool

    public init(id: String = UUID().uuidString, date: Date, programType: WorkoutType,
                durationSec: Int, avgHR: Int, timeInZones: [Int: Int], hrStream: [HRRecord],
                scorePercent: Double? = nil, scoreTier: ScoreTier? = nil,
                trainingDurationSec: Int? = nil, sessionFlag: String? = nil,
                cooldownSkipped: Bool = false) {
        self.id = id
        self.date = date
        self.programType = programType
        self.durationSec = durationSec
        self.avgHR = avgHR
        self.timeInZones = timeInZones
        self.hrStream = hrStream
        self.scorePercent = scorePercent
        self.scoreTier = scoreTier
        self.trainingDurationSec = trainingDurationSec
        self.sessionFlag = sessionFlag
        self.cooldownSkipped = cooldownSkipped
    }
}
