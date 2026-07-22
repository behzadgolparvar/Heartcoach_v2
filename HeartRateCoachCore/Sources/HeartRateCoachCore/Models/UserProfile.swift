import Foundation

/// User's physiological data and app preferences.
/// Used by ZoneCalculator to compute personalised HR zones.
public struct UserProfile: Codable, Sendable {
    /// Age in years. Required for HRmax calculation (220 - age).
    public let age: Int
    /// Resting heart rate in bpm. Required for Karvonen zone calculation.
    public let restingHR: Int
    /// Optional biological sex.
    public let sex: Sex?
    /// Optional weight in kilograms.
    public let weight: Double?
    /// Training goal — fat burn or endurance.
    public let goal: Goal
    /// Default workout type shown on the Home screen.
    public let preferredWorkout: WorkoutType

    public init(age: Int, restingHR: Int, sex: Sex? = nil, weight: Double? = nil,
                goal: Goal, preferredWorkout: WorkoutType) {
        self.age = age
        self.restingHR = restingHR
        self.sex = sex
        self.weight = weight
        self.goal = goal
        self.preferredWorkout = preferredWorkout
    }
}
