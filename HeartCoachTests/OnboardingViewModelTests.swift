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
        vm.fitnessExperience = .intermediate
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
        vm.ageText = "30"; vm.gender = .female; vm.rhrText = "58"; vm.fitnessExperience = .beginner
        XCTAssertTrue(vm.isValid(.demographics))
    }

    func test_invalidAge_failsDemographics() {
        let vm = makeVM()
        vm.ageText = "5"; vm.gender = .male; vm.rhrText = "60"; vm.fitnessExperience = .beginner
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
