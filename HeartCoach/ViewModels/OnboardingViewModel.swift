import Foundation
import HeartRateCoachCore

@Observable
final class OnboardingViewModel {

    enum Step { case physiologicalData, optionalDetails, preferences, zonePreview }

    // Navigation
    var currentStep: Step = .physiologicalData

    // Form input
    var ageText = ""
    var rhrText = ""
    var sex: Sex? = nil
    var weightText = ""
    var goal: Goal = .fatBurn
    var preferredWorkout: WorkoutType = .continuous

    // Computed results
    var computedZones: HRZones?
    var rhrWarning: RHRWarning?

    // UI state
    var fieldError: String?
    var isSaving = false
    var isRequestingHealthKit = false

    /// Called when profile is saved successfully — wired in AppContainer to set appState = .main
    var onComplete: (() -> Void)?

    private let firebaseService: FirebaseServiceProtocol
    private let healthKitService: HealthKitServiceProtocol

    init(firebaseService: FirebaseServiceProtocol, healthKitService: HealthKitServiceProtocol) {
        self.firebaseService = firebaseService
        self.healthKitService = healthKitService
    }

    // MARK: - Navigation

    func advanceStep() {
        fieldError = nil
        switch currentStep {
        case .physiologicalData:
            validateAndComputeZones()
        case .optionalDetails:
            currentStep = .preferences
        case .preferences:
            currentStep = .zonePreview
        case .zonePreview:
            break
        }
    }

    func goBack() {
        fieldError = nil
        switch currentStep {
        case .physiologicalData: break
        case .optionalDetails: currentStep = .physiologicalData
        case .preferences: currentStep = .optionalDetails
        case .zonePreview: break // no back from preview
        }
    }

    // MARK: - HealthKit

    func requestHealthKitAccess() {
        isRequestingHealthKit = true
        Task {
            try? await healthKitService.requestAuthorization()
            await MainActor.run { isRequestingHealthKit = false }
        }
    }

    var isHealthKitAuthorized: Bool { healthKitService.isAuthorized }

    // MARK: - Validation (Step 1)

    private func validateAndComputeZones() {
        guard let age = Int(ageText), !ageText.isEmpty else {
            fieldError = "Please enter your age."
            return
        }
        guard let rhr = Int(rhrText), !rhrText.isEmpty else {
            fieldError = "Please enter your resting heart rate."
            return
        }
        do {
            let result = try ZoneCalculator.calculate(age: age, restingHR: rhr)
            computedZones = result.zones
            rhrWarning = result.warning
            currentStep = .optionalDetails
        } catch ZoneCalculationError.invalidAge {
            fieldError = "Please enter a valid age between 15 and 100."
        } catch ZoneCalculationError.invalidRestingHR {
            fieldError = "Please enter a valid resting heart rate."
        } catch {
            fieldError = "Please check your values and try again."
        }
    }

    // MARK: - Save (Step 4)

    func saveProfile(userID: String) {
        guard let zones = computedZones else { return }
        guard let age = Int(ageText), let rhr = Int(rhrText) else { return }

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
                    onComplete?()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    fieldError = (error as? AppError)?.errorDescription ?? AppError.saveFailed.errorDescription
                }
            }
        }
    }
}
