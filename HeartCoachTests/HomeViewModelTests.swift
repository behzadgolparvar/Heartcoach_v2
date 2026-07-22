import XCTest
import HeartRateCoachCore
@testable import HeartCoach

final class HomeViewModelTests: XCTestCase {

    func testLoadData_noSessions_lastSessionIsNil() async {
        let firebase = MockFirebaseService()
        firebase.profileToReturn = .fixture
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
        firebase.profileToReturn = .fixture
        firebase.sessionsToReturn = [.fixture]
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

// MARK: - Test Fixtures
private extension UserProfile {
    static var fixture: UserProfile {
        UserProfile(age: 30, restingHR: 60, goal: .fatBurn, preferredWorkout: .continuous)
    }
}

private extension Session {
    static var fixture: Session {
        Session(date: Date(), programType: .continuous, durationSec: 2100,
                avgHR: 145, timeInZones: [3: 1200, 4: 600, 2: 300], hrStream: [])
    }
}
