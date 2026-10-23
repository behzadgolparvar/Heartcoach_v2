import Foundation

protocol AuthServiceProtocol: AnyObject {
    var currentUserID: String? { get }
    func signIn(email: String, password: String) async throws -> String
    func signUp(email: String, password: String) async throws -> String
    func sendPasswordReset(email: String) async throws
    func signOut() throws
    func authStateStream() -> AsyncStream<String?>
}
