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
    /// Resolved fitness tier (output of `ExperienceResolver`). Never set directly
    /// in v5 — always written through from Q1/Q2/Ozempic (BR-1b-5). Kept as the
    /// alias every runtime consumer reads.
    public var fitnessExperience: FitnessExperience
    public var mentality: Mentality

    // v5 experience classification (spec §A) — optional-backed so pre-v5
    // profiles decode without throwing; onboarding always populates them.
    /// Q1 training history (authoritative input to the resolver).
    public var q1TrainingHistory: TrainingHistory?
    /// Q2 self-selected tier (independent of Q1).
    public var q2SelfSelect: FitnessExperience?
    /// True when Q1/Q2 disagreed at the extremes (research field, BR-1b-4).
    public var classificationMismatch: Bool

    // v5 program position (spec §1/§B). nil for pre-v5 profiles.
    public var program: ProgramState?

    // v5 Shape-stage placeholders (filled in Phase 5).
    public var dailyOptionSelection: ShapeOption?
    public var muscleGroupPriority: [MuscleGroup]?

    /// Level Up unlock answers (P4) — injury/comfort; nil until Level Up is unlocked.
    public var levelUpUnlock: LevelUpUnlock?
    /// Shape unlock answers (P5) — equipment/focus/pain; nil until Shape is unlocked.
    public var shapeUnlock: ShapeUnlock?

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
                q1TrainingHistory: TrainingHistory? = nil, q2SelfSelect: FitnessExperience? = nil,
                classificationMismatch: Bool = false, program: ProgramState? = nil,
                dailyOptionSelection: ShapeOption? = nil, muscleGroupPriority: [MuscleGroup]? = nil,
                levelUpUnlock: LevelUpUnlock? = nil, shapeUnlock: ShapeUnlock? = nil,
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
        self.q1TrainingHistory = q1TrainingHistory
        self.q2SelfSelect = q2SelfSelect
        self.classificationMismatch = classificationMismatch
        self.program = program
        self.dailyOptionSelection = dailyOptionSelection
        self.muscleGroupPriority = muscleGroupPriority
        self.levelUpUnlock = levelUpUnlock
        self.shapeUnlock = shapeUnlock
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

    // MARK: - v5 completeness (BR-1b-9)

    /// A profile is v5-complete only once the dual-experience answers and the
    /// program state are present. Pre-v5 (Phase-1) profiles report `false` and
    /// are routed to re-onboarding (Q8=B).
    public var isV5Complete: Bool {
        q1TrainingHistory != nil && q2SelfSelect != nil && program?.currentStage != nil
    }
}

// MARK: - Tolerant decoding

/// Custom `init(from:)` so a pre-v5 document (which lacks the v5 keys, including
/// the non-optional `classificationMismatch`) decodes without throwing. All
/// Phase-1 fields are always present; only the v5 additions are optional-tolerant.
/// `encode(to:)` remains synthesized.
extension UserProfileV2 {
    private enum CodingKeys: String, CodingKey {
        case age, gender, weightKg, heightCm, unitsPreference
        case restingHR, maxHROverride
        case goals, fitnessExperience, mentality
        case q1TrainingHistory, q2SelfSelect, classificationMismatch, program
        case dailyOptionSelection, muscleGroupPriority, levelUpUnlock, shapeUnlock
        case healthHistory, facility, device
        case schedule, consent, v2Completed
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        age = try c.decode(Int.self, forKey: .age)
        gender = try c.decode(Gender.self, forKey: .gender)
        weightKg = try c.decodeIfPresent(Double.self, forKey: .weightKg)
        heightCm = try c.decodeIfPresent(Double.self, forKey: .heightCm)
        unitsPreference = try c.decode(UnitsPreference.self, forKey: .unitsPreference)
        restingHR = try c.decode(Int.self, forKey: .restingHR)
        maxHROverride = try c.decodeIfPresent(Int.self, forKey: .maxHROverride)
        goals = try c.decode(Set<TrainingGoal>.self, forKey: .goals)
        fitnessExperience = try c.decode(FitnessExperience.self, forKey: .fitnessExperience)
        mentality = try c.decode(Mentality.self, forKey: .mentality)
        // v5 additions — tolerant of absence on pre-v5 documents.
        q1TrainingHistory = try c.decodeIfPresent(TrainingHistory.self, forKey: .q1TrainingHistory)
        q2SelfSelect = try c.decodeIfPresent(FitnessExperience.self, forKey: .q2SelfSelect)
        classificationMismatch = try c.decodeIfPresent(Bool.self, forKey: .classificationMismatch) ?? false
        program = try c.decodeIfPresent(ProgramState.self, forKey: .program)
        dailyOptionSelection = try c.decodeIfPresent(ShapeOption.self, forKey: .dailyOptionSelection)
        muscleGroupPriority = try c.decodeIfPresent([MuscleGroup].self, forKey: .muscleGroupPriority)
        levelUpUnlock = try c.decodeIfPresent(LevelUpUnlock.self, forKey: .levelUpUnlock)
        shapeUnlock = try c.decodeIfPresent(ShapeUnlock.self, forKey: .shapeUnlock)
        healthHistory = try c.decodeIfPresent(HealthHistory.self, forKey: .healthHistory)
        facility = try c.decodeIfPresent(FacilityInfo.self, forKey: .facility)
        device = try c.decodeIfPresent(DeviceInfo.self, forKey: .device)
        schedule = try c.decode(Schedule.self, forKey: .schedule)
        consent = try c.decode(Consent.self, forKey: .consent)
        v2Completed = try c.decodeIfPresent(Bool.self, forKey: .v2Completed) ?? false
    }
}
