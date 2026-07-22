import Foundation
import AuthenticationServices

protocol AuthServiceProtocol: AnyObject {
    var currentUserID: String? { get }
    /// Exchanges an Apple sign-in result + raw nonce for a Firebase session.
    func signInWithApple(result: Result<ASAuthorization, Error>, rawNonce: String) async throws -> String
    func signOut() throws
    /// Emits the current userID whenever auth state changes. Emits nil when signed out.
    func authStateStream() -> AsyncStream<String?>
}
