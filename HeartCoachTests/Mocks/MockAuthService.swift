import Foundation
@testable import HeartCoach

final class MockAuthService: AuthServiceProtocol {
    var currentUserID: String? = "test-user-id"
    var signInResult: Result<String, Error> = .success("test-user-id")
    var signOutError: Error? = nil
    var authStateSequence: [String?] = ["test-user-id"]

    func signIn(email: String, password: String) async throws -> String {
        switch signInResult {
        case .success(let uid): return uid
        case .failure(let error): throw error
        }
    }

    func signUp(email: String, password: String) async throws -> String {
        switch signInResult {
        case .success(let uid): return uid
        case .failure(let error): throw error
        }
    }

    func signOut() throws {
        if let error = signOutError { throw error }
        currentUserID = nil
    }

    func authStateStream() -> AsyncStream<String?> {
        let sequence = authStateSequence
        return AsyncStream { continuation in
            for uid in sequence { continuation.yield(uid) }
            continuation.finish()
        }
    }
}
