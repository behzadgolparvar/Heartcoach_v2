import Foundation
import HeartRateCoachCore

/// v2 onboarding draft + save. Consent-first, 7 sections (spec order). Nothing is persisted
/// until `save()` runs — which is unreachable until both consents are accepted (BR-1).
@Observable
final class OnboardingViewModel {

    enum Section: Int, CaseIterable {
        case consent, demographics, scheduling, mentality, equipment, goals, device, zones
    }

    var section: Section = .consent

    // Consent
    var healthDataConsent = false
    var remindersConsent = false

    // Demographics / health
    var ageText = ""
    var gender: Gender?
    var weightText = ""
    var weightImperial: Bool
    var heightText = ""
    var heightImperial: Bool
    var rhrText = ""
    var maxHRText = ""
    var occupation: OccupationActivity?
    // v5 dual experience (spec §A): Q1 authoritative, Q2 independent self-select.
    var q1TrainingHistory: TrainingHistory?
    var q2SelfSelect: FitnessExperience?
    // optional health history
    var chronicConditions: Set<ChronicCondition> = []
    var hrMedications: Set<HRMedication> = []
    var onAntiObesityTherapy = false {
        didSet {
            // No → Yes re-triggers the informational override popup (BR-1b-4).
            if onAntiObesityTherapy && !oldValue { showOzempicInfo = true }
        }
    }
    /// Drives the one-time Ozempic/GLP-1 informational popup.
    var showOzempicInfo = false
    var smokingStatus: SmokingStatus?
    var jointIssues: Set<JointIssue> = []

    // Scheduling
    var sessionLengthText = ""
    var frequencyText = ""
    var preferredDays: Set<Weekday> = []
    var timeOfDay: TimeOfDay?
    var reminderMethod: ReminderMethod?

    // Mentality
    var motivationDriver: MotivationDriver?
    var missedResponse: MissedResponse?
    var routinePreference: RoutinePreference?

    // Equipment / facility
    var equipment: Set<Equipment> = []
    var locationPreference: LocationPreference?

    // Goals
    var goals: Set<TrainingGoal> = []

    // Device
    var wearable: Wearable = .appleWatch
    var trackingApps: Set<TrackingApp> = []

    // Derived / UI
    var rhrWarning: RHRWarning?
    var isSaving = false
    var fieldError: String?
    var isHealthKitAuthorized = false

    var onComplete: (() -> Void)?

    /// Clears every answer back to a fresh state — used by "Redo onboarding" so the
    /// flow starts from scratch (the resulting profile also resets program progress).
    func reset() {
        section = .consent
        healthDataConsent = false; remindersConsent = false
        ageText = ""; gender = nil
        weightText = ""; heightText = ""; rhrText = ""; maxHRText = ""; occupation = nil
        q1TrainingHistory = nil; q2SelfSelect = nil
        chronicConditions = []; hrMedications = []
        onAntiObesityTherapy = false; showOzempicInfo = false
        smokingStatus = nil; jointIssues = []
        sessionLengthText = ""; frequencyText = ""; preferredDays = []
        timeOfDay = nil; reminderMethod = nil
        motivationDriver = nil; missedResponse = nil; routinePreference = nil
        equipment = []; locationPreference = nil
        goals = []
        wearable = .appleWatch; trackingApps = []
        rhrWarning = nil; isSaving = false; fieldError = nil; isHealthKitAuthorized = false
        let imperial = Locale.current.measurementSystem == .us
        weightImperial = imperial; heightImperial = imperial
    }

    private let firebaseService: FirebaseServiceProtocol
    private let healthKitService: HealthKitServiceProtocol

    init(firebaseService: FirebaseServiceProtocol, healthKitService: HealthKitServiceProtocol) {
        self.firebaseService = firebaseService
        self.healthKitService = healthKitService
        let imperialLocale = Locale.current.measurementSystem == .us
        self.weightImperial = imperialLocale
        self.heightImperial = imperialLocale
    }

    // MARK: - Derived values

    var weightKg: Double? {
        guard let v = Double(weightText) else { return nil }
        return weightImperial ? UnitConverter.lbsToKg(v) : v
    }
    var heightCm: Double? {
        guard let v = Double(heightText) else { return nil }
        return heightImperial ? UnitConverter.inchesToCm(v) : v
    }
    var bmi: Double? {
        guard let w = weightKg, let h = heightCm else { return nil }
        return BMI.calculate(weightKg: w, heightCm: h)
    }
    var mentalityLean: MentalityLean? {
        guard let m = motivationDriver, let r = missedResponse, let rp = routinePreference else { return nil }
        return Mentality(motivationDriver: m, missedResponse: r, routinePreference: rp).derivedLean
    }
    var computedZones: HRZones? {
        guard let age = Int(ageText), let rhr = Int(rhrText),
              let result = try? ZoneCalculator.calculate(age: age, restingHR: rhr) else { return nil }
        return result.zones
    }

    // MARK: - Per-section validity

    func isValid(_ s: Section) -> Bool {
        switch s {
        case .consent:      return healthDataConsent && remindersConsent
        case .demographics:
            guard let age = Int(ageText), (15...100).contains(age),
                  gender != nil, let rhr = Int(rhrText), rhr > 0,
                  q1TrainingHistory != nil, q2SelfSelect != nil else { return false }
            return true
        case .scheduling:
            guard let len = Int(sessionLengthText), len > 0,
                  let freq = Int(frequencyText), (1...7).contains(freq) else { return false }
            return true
        case .mentality:    return motivationDriver != nil && missedResponse != nil && routinePreference != nil
        case .equipment:    return true      // optional
        case .goals:        return !goals.isEmpty
        case .device:       return true      // optional
        case .zones:        return computedZones != nil
        }
    }

    var canAdvance: Bool { isValid(section) }

    func advance() {
        fieldError = nil
        guard canAdvance else { fieldError = "Please complete the required fields."; return }
        updateWarning()
        if let next = Section(rawValue: section.rawValue + 1) { section = next }
    }

    func back() {
        fieldError = nil
        if let prev = Section(rawValue: section.rawValue - 1) { section = prev }
    }

    private func updateWarning() {
        if let rhr = Int(rhrText) {
            rhrWarning = rhr < 40 ? .belowTypicalRange : (rhr > 100 ? .aboveTypicalRange : nil)
        }
    }

    // MARK: - HealthKit resting-HR prefill

    func prefillRestingHR() {
        Task {
            try? await healthKitService.requestAuthorization()
            let rhr = await healthKitService.fetchRestingHeartRate()
            await MainActor.run {
                self.isHealthKitAuthorized = self.healthKitService.isAuthorized
                if let rhr, self.rhrText.isEmpty { self.rhrText = "\(rhr)" }
            }
        }
    }

    // MARK: - Save

    func save(userID: String) {
        guard let age = Int(ageText), let rhr = Int(rhrText), let gender,
              let q1 = q1TrainingHistory, let q2 = q2SelfSelect,
              let md = motivationDriver, let mr = missedResponse, let rp = routinePreference,
              let len = Int(sessionLengthText), let freq = Int(frequencyText) else {
            fieldError = "Please complete the required fields."
            return
        }
        // BR-1b-2/3/5 — resolve classification (write-through) from Q1/Q2/Ozempic.
        let classification = ExperienceResolver.resolve(q1: q1, q2: q2, onGLP1: onAntiObesityTherapy)

        let healthHistory = HealthHistory(
            chronicConditions: chronicConditions, hrMedications: hrMedications,
            onAntiObesityTherapy: onAntiObesityTherapy, smokingStatus: smokingStatus,
            jointIssues: jointIssues, occupationActivity: occupation)

        let profile = UserProfileV2(
            age: age, gender: gender, weightKg: weightKg, heightCm: heightCm,
            unitsPreference: weightImperial ? .imperial : .metric,
            restingHR: rhr, maxHROverride: Int(maxHRText),
            goals: goals, fitnessExperience: classification.resolved,
            mentality: Mentality(motivationDriver: md, missedResponse: mr, routinePreference: rp),
            q1TrainingHistory: q1, q2SelfSelect: q2,
            classificationMismatch: classification.mismatch,
            program: .newUser(),
            healthHistory: healthHistory.isEmpty ? nil : healthHistory,
            facility: FacilityInfo(equipment: equipment, locationPreference: locationPreference),
            device: DeviceInfo(wearable: wearable, trackingApps: trackingApps),
            schedule: Schedule(sessionLengthMin: len, frequencyPerWeek: freq,
                               preferredDays: preferredDays, preferredTimeOfDay: timeOfDay,
                               reminderMethod: reminderMethod),
            consent: Consent(healthDataConsent: healthDataConsent, remindersConsent: remindersConsent,
                             consentedAt: Date(), consentVersion: "1.0"),
            v2Completed: true)

        isSaving = true
        Task {
            do {
                try await firebaseService.saveProfileV2(profile, userID: userID)
                await MainActor.run { self.isSaving = false; self.onComplete?() }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.fieldError = (error as? AppError)?.errorDescription ?? AppError.saveFailed.errorDescription
                }
            }
        }
    }
}

private extension HealthHistory {
    var isEmpty: Bool {
        chronicConditions.isEmpty && hrMedications.isEmpty && !onAntiObesityTherapy
            && smokingStatus == nil && jointIssues.isEmpty && occupationActivity == nil
    }
}
