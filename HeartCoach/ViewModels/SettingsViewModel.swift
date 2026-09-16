import Foundation
import HeartRateCoachCore

@Observable
final class SettingsViewModel {

    // Editable core fields (zone-affecting + a few key settings)
    var ageText = ""
    var rhrText = ""
    var gender: Gender?
    var goals: Set<TrainingGoal> = []
    var fitnessExperience: FitnessExperience?

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
        loaded = profile
        ageText = "\(profile.age)"
        rhrText = "\(profile.restingHR)"
        gender = profile.gender
        goals = profile.goals
        fitnessExperience = profile.fitnessExperience
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
        if let fitnessExperience { profile.fitnessExperience = fitnessExperience }

        isSaving = true
        Task {
            do {
                try await firebaseService.saveProfileV2(profile, userID: userID)
                await MainActor.run { self.loaded = profile; self.isSaving = false; self.saveSuccess = true }
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
