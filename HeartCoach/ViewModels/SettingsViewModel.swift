import Foundation
import HeartRateCoachCore

@Observable
final class SettingsViewModel {

    // Form fields (mirror current profile)
    var ageText = ""
    var rhrText = ""
    var sex: Sex? = nil
    var weightText = ""
    var goal: Goal = .fatBurn
    var preferredWorkout: WorkoutType = .continuous

    // Zone preview (local only — not saved until user taps Save)
    var previewedZones: HRZones?
    var rhrWarning: RHRWarning?

    // UI state
    var fieldError: String?
    var isSaving = false
    var saveSuccess = false

    private let firebaseService: FirebaseServiceProtocol
    private let authService: AuthServiceProtocol

    init(firebaseService: FirebaseServiceProtocol, authService: AuthServiceProtocol) {
        self.firebaseService = firebaseService
        self.authService = authService
    }

    func populate(from profile: UserProfile) {
        ageText = "\(profile.age)"
        rhrText = "\(profile.restingHR)"
        sex = profile.sex
        weightText = profile.weight.map { "\($0)" } ?? ""
        goal = profile.goal
        preferredWorkout = profile.preferredWorkout
        updatePreview()
    }

    /// Updates the live zone preview whenever age/RHR fields change.
    func updatePreview() {
        guard let age = Int(ageText), let rhr = Int(rhrText) else {
            previewedZones = nil
            rhrWarning = nil
            return
        }
        guard let result = try? ZoneCalculator.calculate(age: age, restingHR: rhr) else {
            previewedZones = nil
            return
        }
        previewedZones = result.zones
        rhrWarning = result.warning
    }

    func save(userID: String) {
        fieldError = nil
        guard let age = Int(ageText), !ageText.isEmpty else {
            fieldError = "Please enter a valid age."
            return
        }
        guard let rhr = Int(rhrText), !rhrText.isEmpty else {
            fieldError = "Please enter a valid resting heart rate."
            return
        }
        let zones: HRZones
        do {
            let result = try ZoneCalculator.calculate(age: age, restingHR: rhr)
            zones = result.zones
            rhrWarning = result.warning
        } catch ZoneCalculationError.invalidAge {
            fieldError = "Please enter a valid age between 15 and 100."
            return
        } catch ZoneCalculationError.invalidRestingHR {
            fieldError = "Please enter a valid resting heart rate."
            return
        } catch {
            fieldError = "Please check your values and try again."
            return
        }

        let weight = Double(weightText)
        let profile = UserProfile(
            age: age, restingHR: rhr, sex: sex, weight: weight,
            goal: goal, preferredWorkout: preferredWorkout
        )

        isSaving = true
        Task {
            do {
                try await firebaseService.saveProfile(profile, zones: zones, userID: userID)
                await MainActor.run {
                    isSaving = false
                    saveSuccess = true
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { self.saveSuccess = false }
            } catch {
                await MainActor.run {
                    isSaving = false
                    fieldError = (error as? AppError)?.errorDescription ?? AppError.saveFailed.errorDescription
                }
            }
        }
    }

    func signOut() {
        try? authService.signOut()
    }
}
