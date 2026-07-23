import Foundation
import AuthenticationServices

@Observable
final class AuthViewModel {

    enum AppState { case loading, signedOut, onboarding, main }

    var appState: AppState = .loading
    var errorMessage: String?
    var isLoading = false

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

    func signInWithApple(result: Result<ASAuthorization, Error>, rawNonce: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let userID = try await authService.signInWithApple(result: result, rawNonce: rawNonce)
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
            let profile = try await firebaseService.loadProfile(userID: userID)
            appState = profile != nil ? .main : .onboarding
        } catch {
            appState = .onboarding
        }
    }
}
