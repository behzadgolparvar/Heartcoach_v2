import Foundation
import AuthenticationServices
import FirebaseAuth

final class FirebaseAuthService: AuthServiceProtocol {

    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }

    func signInWithApple(result: Result<ASAuthorization, Error>, rawNonce: String) async throws -> String {
        switch result {
        case .failure:
            throw AppError.authenticationFailed

        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let tokenString = String(data: tokenData, encoding: .utf8)
            else {
                throw AppError.authenticationFailed
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: rawNonce,
                fullName: credential.fullName
            )

            do {
                let result = try await Auth.auth().signIn(with: firebaseCredential)
                return result.user.uid
            } catch {
                throw AppError.authenticationFailed
            }
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AppError.authenticationFailed
        }
    }

    func authStateStream() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user?.uid)
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
}
