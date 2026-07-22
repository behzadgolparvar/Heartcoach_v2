import Foundation
import CryptoKit

/// Generates cryptographic nonces required for Sign in with Apple + Firebase.
/// Apple mandates a SHA256-hashed nonce to prevent credential replay attacks.
struct AppleSignInNonceGenerator {

    /// Generates a cryptographically random 32-byte nonce as a hex string.
    static func generateRawNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            // SecRandomCopyBytes failure is extremely unlikely on a real device
            fatalError("Unable to generate nonce: SecRandomCopyBytes failed with OSStatus \(result)")
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Returns the SHA256 hash of the input string as a hex-encoded string.
    /// Pass this to ASAuthorizationAppleIDRequest.nonce.
    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
