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
    /// Active phase type at this moment.
    public let phase: PhaseType
    /// Coaching message delivered at this moment, if any.
    public let coachingMessage: String?

    public init(timestamp: Date, second: Int, hr: Int, currentZone: Int,
                targetZone: Int?, phase: PhaseType, coachingMessage: String? = nil) {
        self.timestamp = timestamp
        self.second = second
        self.hr = hr
        self.currentZone = currentZone
        self.targetZone = targetZone
        self.phase = phase
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

    public init(id: String = UUID().uuidString, date: Date, programType: WorkoutType,
                durationSec: Int, avgHR: Int, timeInZones: [Int: Int], hrStream: [HRRecord]) {
        self.id = id
        self.date = date
        self.programType = programType
        self.durationSec = durationSec
        self.avgHR = avgHR
        self.timeInZones = timeInZones
        self.hrStream = hrStream
    }
}
