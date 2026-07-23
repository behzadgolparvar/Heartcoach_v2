import XCTest
import HeartRateCoachCore
@testable import HeartCoach

final class AuthViewModelTests: XCTestCase {

    func testSignInSuccessWithExistingProfile_goesToMain() async {
        let auth = MockAuthService()
        let firebase = MockFirebaseService()
        firebase.profileToReturn = UserProfile.fixture
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)

        await vm.signInWithApple(result: .failure(NSError()), rawNonce: "")
        // signInResult is .success by default in MockAuthService
        auth.signInResult = .success("test-user-id")
        // Trigger check
        vm.checkAuthState()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.appState, .main)
    }

    func testSignInSuccessWithNoProfile_goesToOnboarding() async {
        let auth = MockAuthService()
        let firebase = MockFirebaseService()
        firebase.profileToReturn = nil
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)

        vm.checkAuthState()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.appState, .onboarding)
    }

    func testSignInFailure_setsErrorMessage() async {
        let auth = MockAuthService()
        auth.signInResult = .failure(AppError.authenticationFailed)
        let firebase = MockFirebaseService()
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)

        // signInWithApple is called by the view — simulate a failure result
        auth.authStateSequence = [nil]
        vm.checkAuthState()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.appState, .signedOut)
    }

    func testSignOut_goesToSignedOut() {
        let auth = MockAuthService()
        let firebase = MockFirebaseService()
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)
        vm.appState = .main

        vm.signOut()

        XCTAssertEqual(vm.appState, .signedOut)
    }
}

