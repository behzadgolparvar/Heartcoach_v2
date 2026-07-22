# Logical Components — Unit 2: iPhone Foundation

---

## AppError (Typed Error Enum)

**Purpose**: Single error vocabulary for the entire app. Service layer maps all infrastructure errors (Firebase, HealthKit, Core Data) to these cases before throwing. ViewModels only see `AppError`.

```swift
enum AppError: Error {
    case networkUnavailable          // no internet connection
    case permissionDenied            // Firebase security rule rejected
    case authenticationFailed        // Sign in with Apple or Firebase auth error
    case profileNotFound             // loadProfile returned nil (unexpected)
    case saveFailed                  // Firestore write failed
    case healthKitUnauthorized       // HR access not granted
    case unknown                     // catch-all for unexpected errors
}
```

**User-facing messages** (defined in `AppError+LocalizedDescription`):
- `.networkUnavailable` → "No internet connection. Please try again."
- `.saveFailed` → "Save failed. Please try again."
- `.authenticationFailed` → "Sign in failed. Please try again."
- `.unknown` → "Something went wrong. Please try again."

---

## AppleSignInNonceGenerator

**Purpose**: Generates the cryptographic nonce required for Sign in with Apple + Firebase. Stateless utility — static methods only.

```swift
struct AppleSignInNonceGenerator {
    /// Generates a random 32-byte nonce as a hex string.
    static func generateRawNonce() -> String

    /// Returns the SHA256 hash of the given string (passed to Apple's request).
    static func sha256(_ input: String) -> String
}
```

Used only by `FirebaseAuthService.signInWithApple()`. Not imported by any ViewModel.

---

## PendingSession (Core Data Entity)

**Purpose**: Stores a single queued `Session` as a JSON blob while Firebase is unreachable.

**Core Data entity definition (`OfflineQueue.xcdatamodeld`)**:

| Attribute | Type | Notes |
|---|---|---|
| `id` | String | Session UUID — used to deduplicate and mark synced |
| `payload` | Binary Data | `JSONEncoder().encode(session)` — entire `Session` struct |
| `createdAt` | Date | Insertion time — used for ordering and debugging |

**Why JSON blob (Q1 — A)**:
- `Session.hrStream` can contain 400+ `HRRecord` values — a JSON blob handles this in one attribute
- Schema stays stable even if `Session` adds fields in future versions
- Queue's only job is store → upload → delete; no need to query individual fields

---

## CoreDataOfflineQueue

**Purpose**: Concrete implementation of `OfflineSessionQueueProtocol`. Wraps `NSPersistentContainer`.

```swift
final class CoreDataOfflineQueue: OfflineSessionQueueProtocol {
    private let container: NSPersistentContainer

    func enqueue(_ session: Session) throws
        // JSONEncoder → PendingSession entity → save context

    func pendingSessions() throws -> [Session]
        // fetch all PendingSession → JSONDecoder → [Session]

    func markSynced(id: String) throws
        // fetch by id → delete → save context
}
```

**Core Data setup**:
- `NSPersistentContainer(name: "OfflineQueue")`
- Store URL: app's `Documents` directory (persists across launches)
- `NSFileProtectionComplete` applied to the store file (SECURITY-01)

---

## NetworkMonitor

**Purpose**: Wraps `NWPathMonitor` and publishes connectivity changes as an `AsyncStream<Bool>`. Singleton in `AppContainer`.

```swift
final class NetworkMonitor {
    var isConnectedStream: AsyncStream<Bool> { get }
    var isCurrentlyConnected: Bool { get }

    init()   // starts NWPathMonitor on a background DispatchQueue
}
```

**Usage in FirestoreService**:
```swift
Task {
    for await isConnected in networkMonitor.isConnectedStream {
        if isConnected { await syncPendingSessions() }
    }
}
```

Only one `NWPathMonitor` instance exists in the app — owned by `NetworkMonitor` in `AppContainer`.

---

## FirebaseAuthService

**Purpose**: Concrete implementation of `AuthServiceProtocol`. Handles Sign in with Apple credential → Firebase ID token exchange.

Key internal flow:
```
signInWithApple():
  1. AppleSignInNonceGenerator.generateRawNonce()
  2. sha256(rawNonce) → hashedNonce
  3. ASAuthorizationAppleIDRequest(nonce: hashedNonce)
  4. Present ASAuthorizationController
  5. On credential received:
     → OAuthProvider.credential(appleIDToken, rawNonce)
     → Auth.auth().signIn(with: credential)
  6. Return userID
  7. On any error → throw AppError.authenticationFailed
```

---

## FirestoreService

**Purpose**: Concrete implementation of `FirebaseServiceProtocol`. All Firestore paths follow the schema defined in NFR requirements.

Firestore path constants (defined once, used throughout):
```swift
// users/{userID}
static func userDoc(_ id: String) -> String { "users/\(id)" }

// users/{userID}/sessions/{sessionID}
static func sessionDoc(_ userID: String, _ sessionID: String) -> String {
    "users/\(userID)/sessions/\(sessionID)"
}
```

**loadSessions query (Home screen)**:
```swift
Firestore.firestore()
    .collection("users/\(userID)/sessions")
    .order(by: "date", descending: true)
    .limit(to: 1)       // Home screen only needs last session
    .getDocuments()
```

**Error mapping** (all catch blocks):
```swift
} catch let error as NSError {
    switch error.domain {
    case FirestoreErrorDomain:
        if error.code == FirestoreErrorCode.unavailable.rawValue {
            throw AppError.networkUnavailable
        }
    default:
        throw AppError.unknown
    }
}
```

---

## HealthKitService

**Purpose**: Concrete implementation of `HealthKitServiceProtocol`. Handles HR read authorization only (write access is not needed — Watch reads HR directly via HKWorkoutSession in Unit 4).

```swift
final class HealthKitService: HealthKitServiceProtocol {
    private let store = HKHealthStore()
    private let hrType = HKQuantityType(.heartRate)

    var isAuthorized: Bool {
        store.authorizationStatus(for: hrType) == .sharingAuthorized
    }

    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: [], read: [hrType])
    }
}
```

**Note**: `HKHealthStore.authorizationStatus` does not distinguish between "not yet asked" and "denied" — both return `.notDetermined` or `.sharingDenied`. Use `isAuthorized` (which checks `.sharingAuthorized`) to gate the Start Workout button.

---

## Component Dependencies

```
AppContainer
  ├── FirebaseAuthService      ← uses AppleSignInNonceGenerator
  ├── FirestoreService         ← uses NetworkMonitor, CoreDataOfflineQueue
  ├── HealthKitService
  ├── CoreDataOfflineQueue
  └── NetworkMonitor

AuthViewModel        ← FirebaseAuthService, FirestoreService
OnboardingViewModel  ← FirestoreService, HealthKitService, ZoneCalculator (Unit 1)
HomeViewModel        ← FirestoreService, HealthKitService, NetworkMonitor
SettingsViewModel    ← FirestoreService, ZoneCalculator (Unit 1)
```
