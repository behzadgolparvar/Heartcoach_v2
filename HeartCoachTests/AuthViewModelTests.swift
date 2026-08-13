import XCTest
import HeartRateCoachCore
@testable import HeartCoach

final class AuthViewModelTests: XCTestCase {

    func testSignIn_withExistingProfile_goesToMain() async {
        let auth = MockAuthService()
        let firebase = MockFirebaseService()
        firebase.profileToReturn = UserProfile.fixture
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)

        vm.email = "test@example.com"
        vm.password = "password123"
        await vm.submitAuth()

        XCTAssertEqual(vm.appState, .main)
    }

    func testSignIn_withNoProfile_goesToOnboarding() async {
        let auth = MockAuthService()
        let firebase = MockFirebaseService()
        firebase.profileToReturn = nil
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)

        vm.email = "test@example.com"
        vm.password = "password123"
        await vm.submitAuth()

        XCTAssertEqual(vm.appState, .onboarding)
    }

    func testSignIn_failure_setsErrorMessage() async {
        let auth = MockAuthService()
        auth.signInResult = .failure(AppError.authenticationFailed)
        let firebase = MockFirebaseService()
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)

        vm.email = "test@example.com"
        vm.password = "wrongpass"
        await vm.submitAuth()

        XCTAssertNotNil(vm.errorMessage)
    }

    func testSignUp_withNoProfile_goesToOnboarding() async {
        let auth = MockAuthService()
        let firebase = MockFirebaseService()
        firebase.profileToReturn = nil
        let vm = AuthViewModel(authService: auth, firebaseService: firebase)
        vm.isSignUpMode = true

        vm.email = "new@example.com"
        vm.password = "newpass123"
        await vm.submitAuth()

        XCTAssertEqual(vm.appState, .onboarding)
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
