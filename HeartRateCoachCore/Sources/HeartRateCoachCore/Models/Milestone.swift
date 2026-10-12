import Foundation

/// A biweekly outcome check-in (§H / FR-10).
public struct Milestone: Codable, Sendable, Equatable {
    public let date: Date
    public let restingHR: Int?      // HealthKit (nil-tolerant, Q2)
    public let weightKg: Double?

    public init(date: Date, restingHR: Int?, weightKg: Double?) {
        self.date = date
        self.restingHR = restingHR
        self.weightKg = weightKg
    }
}

/// Persisted milestone state on the profile.
public struct MilestoneState: Codable, Sendable, Equatable {
    public var lastMilestoneDate: Date?
    public var history: [Milestone]

    public init(lastMilestoneDate: Date? = nil, history: [Milestone] = []) {
        self.lastMilestoneDate = lastMilestoneDate
        self.history = history
    }
}

/// Weight-entry gating state (§H, Q3).
public enum WeightGateState: Sendable, Equatable {
    case ok            // not overdue / logged
    case remind        // Day 1 missed
    case blockWorkout  // Day ≥2 missed — block starting a workout
}
