import Foundation
import HeartRateCoachCore

@Observable
final class SettingsViewModel {

    // Editable core fields (zone-affecting + a few key settings)
    var ageText = ""
    var rhrText = ""
    var gender: Gender?
    var goals: Set<TrainingGoal> = []
    // v5 experience is edited via Q1/Q2 + Ozempic and re-resolved (BR-1b-4/5);
    // the resolved tier is never edited directly.
    var q1TrainingHistory: TrainingHistory?
    var q2SelfSelect: FitnessExperience?
    var onAntiObesityTherapy = false {
        didSet { if onAntiObesityTherapy && !oldValue && !isPopulating { showOzempicInfo = true } }
    }
    var showOzempicInfo = false
    /// Suppresses the Ozempic popup while `populate(from:)` seeds fields from a loaded profile.
    private var isPopulating = false

    /// Live preview of the resolved tier for the current Q1/Q2/Ozempic selection.
    var resolvedExperience: FitnessExperience? {
        guard let q1 = q1TrainingHistory, let q2 = q2SelfSelect else { return nil }
        return ExperienceResolver.resolve(q1: q1, q2: q2, onGLP1: onAntiObesityTherapy).resolved
    }

    var previewedZones: HRZones?
    var rhrWarning: RHRWarning?
    var fieldError: String?
    var isSaving = false
    var saveSuccess = false

    /// The full profile currently on file — edits are merged onto this so non-edited
    /// v2 fields (mentality, schedule, health, etc.) are preserved.
    private var loaded: UserProfileV2?

    private let firebaseService: FirebaseServiceProtocol
    private let authService: AuthServiceProtocol

    init(firebaseService: FirebaseServiceProtocol, authService: AuthServiceProtocol) {
        self.firebaseService = firebaseService
        self.authService = authService
    }

    func populate(from profile: UserProfileV2) {
        isPopulating = true
        defer { isPopulating = false }
        loaded = profile
        ageText = "\(profile.age)"
        rhrText = "\(profile.restingHR)"
        gender = profile.gender
        goals = profile.goals
        q1TrainingHistory = profile.q1TrainingHistory
        q2SelfSelect = profile.q2SelfSelect
        onAntiObesityTherapy = profile.healthHistory?.onAntiObesityTherapy ?? false
        updatePreview()
    }

    func updatePreview() {
        guard let age = Int(ageText), let rhr = Int(rhrText),
              let result = try? ZoneCalculator.calculate(age: age, restingHR: rhr) else {
            previewedZones = nil; rhrWarning = nil; return
        }
        previewedZones = result.zones
        rhrWarning = result.warning
    }

    func save(userID: String) {
        fieldError = nil
        guard let age = Int(ageText), (15...100).contains(age) else {
            fieldError = "Please enter a valid age between 15 and 100."; return
        }
        guard let rhr = Int(rhrText), rhr > 0 else {
            fieldError = "Please enter a valid resting heart rate."; return
        }
        guard var profile = loaded else {
            fieldError = "Profile not loaded yet."; return
        }
        profile.age = age
        profile.restingHR = rhr
        if let gender { profile.gender = gender }
        if !goals.isEmpty { profile.goals = goals }

        // v5 experience: re-resolve from Q1/Q2/Ozempic and write through
        // (BR-1b-4/5). Training stage + progression are never touched (BR-1b-6).
        profile.q1TrainingHistory = q1TrainingHistory
        profile.q2SelfSelect = q2SelfSelect
        if let q1 = q1TrainingHistory, let q2 = q2SelfSelect {
            let classification = ExperienceResolver.resolve(q1: q1, q2: q2, onGLP1: onAntiObesityTherapy)
            profile.fitnessExperience = classification.resolved
            profile.classificationMismatch = classification.mismatch
        }
        // Persist the Ozempic flag onto health history (create one if absent).
        var health = profile.healthHistory ?? HealthHistory()
        health.onAntiObesityTherapy = onAntiObesityTherapy
        profile.healthHistory = health

        isSaving = true
        let snapshot = profile   // immutable copy for the concurrent save (Swift 6)
        Task {
            do {
                try await firebaseService.saveProfileV2(snapshot, userID: userID)
                await MainActor.run { self.loaded = snapshot; self.isSaving = false; self.saveSuccess = true }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { self.saveSuccess = false }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.fieldError = (error as? AppError)?.errorDescription ?? AppError.saveFailed.errorDescription
                }
            }
        }
    }

    func signOut() { try? authService.signOut() }
}
