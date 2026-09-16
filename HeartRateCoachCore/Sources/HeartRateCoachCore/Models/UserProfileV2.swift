import Foundation

/// v2 user profile — the full onboarding aggregate (spec §5.1).
/// Canonical measurements are stored metric; imperial is derived for display via `UnitConverter`.
/// Replaces v1 `UserProfile` once the legacy workout engine is retired.
public struct UserProfileV2: Codable, Sendable, Equatable {
    // profile
    public var age: Int
    public var gender: Gender
    public var weightKg: Double?
    public var heightCm: Double?
    public var unitsPreference: UnitsPreference

    // physiology
    public var restingHR: Int
    /// Optional manual Max HR override; when nil, `effectiveMaxHR` uses 220 − age.
    public var maxHROverride: Int?

    // settings
    public var goals: Set<TrainingGoal>
    public var fitnessExperience: FitnessExperience
    public var mentality: Mentality

    // optional sections
    public var healthHistory: HealthHistory?
    public var facility: FacilityInfo?
    public var device: DeviceInfo?

    // scheduling + consent + onboarding
    public var schedule: Schedule
    public var consent: Consent
    public var v2Completed: Bool

    public init(age: Int, gender: Gender, weightKg: Double? = nil, heightCm: Double? = nil,
                unitsPreference: UnitsPreference, restingHR: Int, maxHROverride: Int? = nil,
                goals: Set<TrainingGoal>, fitnessExperience: FitnessExperience, mentality: Mentality,
                healthHistory: HealthHistory? = nil, facility: FacilityInfo? = nil,
                device: DeviceInfo? = nil, schedule: Schedule, consent: Consent, v2Completed: Bool = false) {
        self.age = age
        self.gender = gender
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.unitsPreference = unitsPreference
        self.restingHR = restingHR
        self.maxHROverride = maxHROverride
        self.goals = goals
        self.fitnessExperience = fitnessExperience
        self.mentality = mentality
        self.healthHistory = healthHistory
        self.facility = facility
        self.device = device
        self.schedule = schedule
        self.consent = consent
        self.v2Completed = v2Completed
    }

    // MARK: - Derived

    /// Max HR used for training: manual override if set, else 220 − age.
    public var effectiveMaxHR: Int { maxHROverride ?? (220 - age) }

    /// Body-mass index, present only when both height and weight are known.
    public var bmi: Double? {
        guard let weightKg, let heightCm, heightCm > 0 else { return nil }
        return BMI.calculate(weightKg: weightKg, heightCm: heightCm)
    }

    /// The user's overall mentality lean for the assignment engine.
    public var mentalityLean: MentalityLean { mentality.derivedLean }

    /// Karvonen HR zones (reuses v1 `ZoneCalculator`).
    public func computeZones() throws -> HRZones {
        try ZoneCalculator.calculate(age: age, restingHR: restingHR).zones
    }
}
