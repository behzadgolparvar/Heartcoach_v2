import XCTest
import HeartRateCoachCore
@testable import HeartCoach

final class OnboardingViewModelTests: XCTestCase {

    private func makeVM(firebase: MockFirebaseService = MockFirebaseService(),
                        hk: MockHealthKitService = MockHealthKitService()) -> OnboardingViewModel {
        OnboardingViewModel(firebaseService: firebase, healthKitService: hk)
    }

    /// Fills every required field so the flow is completable.
    private func completeRequiredFields(_ vm: OnboardingViewModel) {
        vm.healthDataConsent = true
        vm.remindersConsent = true
        vm.ageText = "30"
        vm.gender = .male
        vm.rhrText = "60"
        vm.q1TrainingHistory = .recentReturnOrUnderYear
        vm.q2SelfSelect = .intermediate
        vm.sessionLengthText = "35"
        vm.frequencyText = "3"
        vm.motivationDriver = .outcome
        vm.missedResponse = .goal
        vm.routinePreference = .variety
        vm.goals = [.fastWeightLoss]
    }

    func test_startsAtConsent() {
        XCTAssertEqual(makeVM().section, .consent)
    }

    func test_consentGating_blocksAdvanceUntilBothAccepted() {
        let vm = makeVM()
        XCTAssertFalse(vm.isValid(.consent))
        vm.healthDataConsent = true
        XCTAssertFalse(vm.isValid(.consent))
        vm.remindersConsent = true
        XCTAssertTrue(vm.isValid(.consent))
    }

    func test_advance_blockedWhenSectionInvalid() {
        let vm = makeVM()
        vm.advance()                       // consent not accepted
        XCTAssertEqual(vm.section, .consent)
        XCTAssertNotNil(vm.fieldError)
    }

    func test_demographicsValidity_requiresCoreFields() {
        let vm = makeVM()
        XCTAssertFalse(vm.isValid(.demographics))
        vm.ageText = "30"; vm.gender = .female; vm.rhrText = "58"
        vm.q1TrainingHistory = .neverTrained; vm.q2SelfSelect = .beginner
        XCTAssertTrue(vm.isValid(.demographics))
    }

    func test_invalidAge_failsDemographics() {
        let vm = makeVM()
        vm.ageText = "5"; vm.gender = .male; vm.rhrText = "60"
        vm.q1TrainingHistory = .neverTrained; vm.q2SelfSelect = .beginner
        XCTAssertFalse(vm.isValid(.demographics))
    }

    func test_goalsRequireAtLeastOne() {
        let vm = makeVM()
        XCTAssertFalse(vm.isValid(.goals))
        vm.goals = [.routine]
        XCTAssertTrue(vm.isValid(.goals))
    }

    func test_computedZones_andMentalityLean() {
        let vm = makeVM()
        completeRequiredFields(vm)
        XCTAssertNotNil(vm.computedZones)
        XCTAssertEqual(vm.mentalityLean, .outcome) // outcome+goal+variety = 3 → outcome
    }

    func test_rhrWarning_belowRange() {
        let vm = makeVM()
        completeRequiredFields(vm)
        vm.rhrText = "35"
        vm.advance()  // from consent... but section is consent; advancing updates warning only when leaving demographics
        // directly exercise warning via demographics advance
        vm.section = .demographics
        vm.advance()
        XCTAssertEqual(vm.rhrWarning, .belowTypicalRange)
    }

    func test_save_success_savesV2AndCallsOnComplete() async {
        let firebase = MockFirebaseService()
        let vm = makeVM(firebase: firebase)
        completeRequiredFields(vm)
        var completed = false
        vm.onComplete = { completed = true }

        vm.save(userID: "u1")
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(completed)
        XCTAssertEqual(firebase.savedProfilesV2.count, 1)
        XCTAssertTrue(firebase.savedProfilesV2.first?.v2Completed == true)
    }

    func test_save_resolvesExperienceAndInitsFoundationProgram() async {
        let firebase = MockFirebaseService()
        let vm = makeVM(firebase: firebase)
        completeRequiredFields(vm)                 // q1 = recentReturn (→ intermediate), q2 = intermediate

        vm.save(userID: "u1")
        try? await Task.sleep(nanoseconds: 200_000_000)

        let saved = firebase.savedProfilesV2.first
        XCTAssertEqual(saved?.fitnessExperience, .intermediate)   // matrix: q1 wins
        XCTAssertEqual(saved?.classificationMismatch, false)
        XCTAssertEqual(saved?.program?.currentStage, .foundation)
        XCTAssertEqual(saved?.program?.currentProgress.sessionsCompleted, 0)
        XCTAssertEqual(saved?.isV5Complete, true)
    }

    func test_save_ozempicForcesBeginner() async {
        let firebase = MockFirebaseService()
        let vm = makeVM(firebase: firebase)
        completeRequiredFields(vm)
        vm.q1TrainingHistory = .overYearConsistent   // → advanced
        vm.q2SelfSelect = .advanced
        vm.onAntiObesityTherapy = true               // override → beginner

        vm.save(userID: "u1")
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(firebase.savedProfilesV2.first?.fitnessExperience, .beginner)
    }

    func test_ozempicToggle_triggersInfoPopup() {
        let vm = makeVM()
        XCTAssertFalse(vm.showOzempicInfo)
        vm.onAntiObesityTherapy = true
        XCTAssertTrue(vm.showOzempicInfo)
    }

    func test_save_failure_setsFieldError() async {
        let firebase = MockFirebaseService()
        firebase.shouldThrow = .saveFailed
        let vm = makeVM(firebase: firebase)
        completeRequiredFields(vm)

        vm.save(userID: "u1")
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(vm.fieldError)
    }
}
