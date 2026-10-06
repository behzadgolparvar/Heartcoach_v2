import Foundation

@Observable
final class AuthViewModel {

    enum AppState { case loading, signedOut, onboarding, main, loadError }

    var appState: AppState = .loading
    var errorMessage: String?
    var isLoading = false
    var isSignUpMode = false
    var email = ""
    var password = ""

    var currentUserID: String? { authService.currentUserID }

    private let authService: AuthServiceProtocol
    private let firebaseService: FirebaseServiceProtocol

    init(authService: AuthServiceProtocol, firebaseService: FirebaseServiceProtocol) {
        self.authService = authService
        self.firebaseService = firebaseService
    }

    func checkAuthState() {
        Task {
            for await userID in authService.authStateStream() {
                await handleAuthState(userID: userID)
            }
        }
    }

    func submitAuth() async {
        isLoading = true
        errorMessage = nil
        do {
            let userID = isSignUpMode
                ? try await authService.signUp(email: email, password: password)
                : try await authService.signIn(email: email, password: password)
            await handleAuthState(userID: userID)
        } catch {
            errorMessage = (error as? AppError)?.errorDescription ?? AppError.authenticationFailed.errorDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try authService.signOut()
            appState = .signedOut
        } catch {
            errorMessage = AppError.authenticationFailed.errorDescription
        }
    }

    @MainActor
    private func handleAuthState(userID: String?) async {
        guard let userID else {
            appState = .signedOut
            return
        }
        do {
            // A successful load with a v5-complete profile → main; otherwise
            // full re-onboarding (BR-1b-9 / Q8=B). Pre-v5 (Phase-1) profiles lack
            // the dual-experience answers and program state, so they re-onboard.
            let profile = try await firebaseService.loadProfileV2(userID: userID)
            appState = (profile?.isV5Complete == true) ? .main : .onboarding
        } catch {
            // A failed load (network, permissions) must NOT drop the user into
            // onboarding — that risks overwriting existing data. Surface a retry instead.
            errorMessage = (error as? AppError)?.errorDescription ?? AppError.unknown.errorDescription
            appState = .loadError
        }
    }

    /// Re-attempts loading the profile after a load failure (used by the error screen).
    @MainActor
    func retryLoad() async {
        errorMessage = nil
        appState = .loading
        await handleAuthState(userID: authService.currentUserID)
    }
}
