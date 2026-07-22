import XCTest
@testable import HeartCoach

final class OnboardingViewModelTests: XCTestCase {

    private func makeVM(firebase: MockFirebaseService = MockFirebaseService(),
                        hk: MockHealthKitService = MockHealthKitService()) -> OnboardingViewModel {
        OnboardingViewModel(firebaseService: firebase, healthKitService: hk)
    }

    func testStep1_invalidAge_setsFieldError() {
        let vm = makeVM()
        vm.ageText = "5"
        vm.rhrText = "60"
        vm.advanceStep()
        XCTAssertNotNil(vm.fieldError)
        XCTAssertEqual(vm.currentStep, .physiologicalData)
    }

    func testStep1_emptyAge_setsFieldError() {
        let vm = makeVM()
        vm.ageText = ""
        vm.rhrText = "60"
        vm.advanceStep()
        XCTAssertNotNil(vm.fieldError)
    }

    func testStep1_validInputs_computesZonesAndAdvances() {
        let vm = makeVM()
        vm.ageText = "30"
        vm.rhrText = "60"
        vm.advanceStep()
        XCTAssertNil(vm.fieldError)
        XCTAssertNotNil(vm.computedZones)
        XCTAssertEqual(vm.currentStep, .optionalDetails)
    }

    func testStep1_rhrWarningRange_computesZonesWithWarning() {
        let vm = makeVM()
        vm.ageText = "30"
        vm.rhrText = "35" // below typical range
        vm.advanceStep()
        XCTAssertNotNil(vm.computedZones)
        XCTAssertNotNil(vm.rhrWarning)
        XCTAssertEqual(vm.currentStep, .optionalDetails)
    }

    func testStep2_advancesToPreferences() {
        let vm = makeVM()
        vm.ageText = "30"; vm.rhrText = "60"; vm.advanceStep() // → optionalDetails
        vm.advanceStep()
        XCTAssertEqual(vm.currentStep, .preferences)
    }

    func testStep3_advancesToZonePreview() {
        let vm = makeVM()
        vm.ageText = "30"; vm.rhrText = "60"; vm.advanceStep()
        vm.advanceStep()
        vm.advanceStep()
        XCTAssertEqual(vm.currentStep, .zonePreview)
    }

    func testSaveProfile_success_callsOnComplete() async {
        let firebase = MockFirebaseService()
        let vm = makeVM(firebase: firebase)
        vm.ageText = "30"; vm.rhrText = "60"; vm.advanceStep() // compute zones
        vm.advanceStep(); vm.advanceStep() // reach preview

        var completeCalled = false
        vm.onComplete = { completeCalled = true }

        vm.saveProfile(userID: "test-user")
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(completeCalled)
        XCTAssertEqual(firebase.savedProfiles.count, 1)
    }

    func testSaveProfile_failure_setsFieldError() async {
        let firebase = MockFirebaseService()
        firebase.shouldThrow = .saveFailed
        let vm = makeVM(firebase: firebase)
        vm.ageText = "30"; vm.rhrText = "60"; vm.advanceStep()
        vm.advanceStep(); vm.advanceStep()

        vm.saveProfile(userID: "test-user")
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(vm.fieldError)
    }
}
