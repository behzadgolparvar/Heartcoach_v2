import XCTest
import HeartRateCoachCore
@testable import HeartCoach

final class HomeViewModelTests: XCTestCase {

    func testLoadData_noSessions_lastSessionIsNil() async {
        let firebase = MockFirebaseService()
        firebase.profileToReturn = UserProfile.fixture
        firebase.sessionsToReturn = []
        let hk = MockHealthKitService()
        let vm = HomeViewModel(firebaseService: firebase, healthKitService: hk)

        vm.loadData(userID: "test-user")
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNil(vm.lastSession)
        XCTAssertNotNil(vm.profile)
    }

    func testLoadData_withSessions_lastSessionPopulated() async {
        let firebase = MockFirebaseService()
        firebase.profileToReturn = UserProfile.fixture
        firebase.sessionsToReturn = [Session.fixture]
        let hk = MockHealthKitService()
        let vm = HomeViewModel(firebaseService: firebase, healthKitService: hk)

        vm.loadData(userID: "test-user")
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(vm.lastSession)
    }

    func testHealthKitDenied_isAuthorizedFalse() {
        let firebase = MockFirebaseService()
        let hk = MockHealthKitService()
        hk.isAuthorized = false
        let vm = HomeViewModel(firebaseService: firebase, healthKitService: hk)

        vm.recheckHealthKitStatus()

        XCTAssertFalse(vm.isHealthKitAuthorized)
    }

    func testHealthKitGranted_afterRecheck_isAuthorizedTrue() {
        let firebase = MockFirebaseService()
        let hk = MockHealthKitService()
        hk.isAuthorized = true
        let vm = HomeViewModel(firebaseService: firebase, healthKitService: hk)

        vm.recheckHealthKitStatus()

        XCTAssertTrue(vm.isHealthKitAuthorized)
    }
}

