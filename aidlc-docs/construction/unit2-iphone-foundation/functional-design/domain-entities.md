# Domain Entities — Unit 2: iPhone Foundation

Unit 2 imports all value types from `HeartRateCoachCore`. This document defines the additional types introduced in Unit 2: app state enums, service protocols, and ViewModel state types.

---

## AppState (enum)

Controls which root UI the app displays. Managed by `AuthViewModel`.

| Case | Description |
|---|---|
| `.loading` | App has just launched — checking Firebase auth state |
| `.signedOut` | No authenticated user — show `SignInView` |
| `.onboarding` | Authenticated but no profile in Firestore — show onboarding wizard |
| `.main` | Authenticated + profile exists — show `MainTabView` |

---

## OnboardingStep (enum)

Tracks which step of the 4-step wizard is active. Managed by `OnboardingViewModel`.

| Case | Description |
|---|---|
| `.physiologicalData` | Step 1 — age, RHR, HealthKit authorization |
| `.optionalDetails` | Step 2 — sex, weight (skippable) |
| `.preferences` | Step 3 — goal, preferred workout type |
| `.zonePreview` | Step 4 — computed zones shown, "Start Training" triggers save |

---

## OnboardingDraft (struct)

Mutable buffer holding user input during the onboarding wizard. Not persisted until Step 4 completes.

| Property | Type | Required |
|---|---|---|
| `age` | `String` | Yes (validated on Next) |
| `restingHR` | `String` | Yes (validated on Next) |
| `sex` | `Sex?` | No |
| `weight` | `String` | No |
| `goal` | `Goal` | Yes (default: `.fatBurn`) |
| `preferredWorkout` | `WorkoutType` | Yes (default: `.continuous`) |

Uses `String` for age and RHR to allow free-form typing before validation.

---

## AuthServiceProtocol (protocol)

Defines authentication operations. Implemented by `FirebaseAuthService`.

```swift
protocol AuthServiceProtocol {
    var currentUserID: String? { get }
    func signInWithApple() async throws -> String   // returns userID
    func signOut() throws
    func authStateStream() -> AsyncStream<String?>  // emits userID or nil
}
```

---

## FirebaseServiceProtocol (protocol)

Defines all Firestore read/write operations. Implemented by `FirestoreService`.

```swift
protocol FirebaseServiceProtocol {
    func saveProfile(_ profile: UserProfile, zones: HRZones, userID: String) async throws
    func loadProfile(userID: String) async throws -> UserProfile?
    func loadZones(userID: String) async throws -> HRZones?
    func saveSession(_ session: Session, userID: String) async throws
    func loadSessions(userID: String) async throws -> [Session]
}
```

---

## HealthKitServiceProtocol (protocol)

Defines HealthKit HR authorization. Implemented by `HealthKitService`.

```swift
protocol HealthKitServiceProtocol {
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
}
```

---

## OfflineSessionQueueProtocol (protocol)

Defines local Core Data queue for sessions when Firebase is unreachable.

```swift
protocol OfflineSessionQueueProtocol {
    func enqueue(_ session: Session) throws
    func pendingSessions() throws -> [Session]
    func markSynced(id: String) throws
}
```

---

## AuthViewModel (@Observable)

| Property | Type | Description |
|---|---|---|
| `appState` | `AppState` | Current root navigation state |
| `errorMessage` | `String?` | Sign-in error shown on SignInView |
| `isLoading` | `Bool` | True while auth is in progress |

Key methods: `signInWithApple()`, `signOut()`, `checkAuthState()`

---

## OnboardingViewModel (@Observable)

| Property | Type | Description |
|---|---|---|
| `currentStep` | `OnboardingStep` | Active wizard step |
| `draft` | `OnboardingDraft` | Live user input buffer |
| `computedZones` | `HRZones?` | Calculated after Step 1 validation |
| `rhrWarning` | `RHRWarning?` | Soft warning if RHR outside 40–100 |
| `fieldError` | `String?` | Inline validation error on form fields |
| `isSaving` | `Bool` | True while Firestore write is in progress |

Key methods: `advanceStep()`, `goBack()`, `saveProfile()`

---

## HomeViewModel (@Observable)

| Property | Type | Description |
|---|---|---|
| `profile` | `UserProfile?` | Loaded user profile |
| `zones` | `HRZones?` | Loaded HR zones |
| `lastSession` | `Session?` | Most recent completed session (nil = show zone card) |
| `isLoading` | `Bool` | True while loading from Firestore |

Key methods: `loadData()`

---

## SettingsViewModel (@Observable)

| Property | Type | Description |
|---|---|---|
| `draft` | `OnboardingDraft` | Editable copy of current profile |
| `computedZones` | `HRZones?` | Preview of recalculated zones |
| `rhrWarning` | `RHRWarning?` | Soft warning if RHR outside 40–100 |
| `fieldError` | `String?` | Inline validation error |
| `isSaving` | `Bool` | True while Firestore write is in progress |
| `saveSuccess` | `Bool` | True briefly after successful save |

Key methods: `previewZones()`, `save()`

---

## AppContainer (class — composition root)

Singleton. Creates and holds all service instances. Injected into the SwiftUI environment at app startup.

| Property | Type |
|---|---|
| `authService` | `AuthServiceProtocol` |
| `firebaseService` | `FirebaseServiceProtocol` |
| `healthKitService` | `HealthKitServiceProtocol` |
| `offlineQueue` | `OfflineSessionQueueProtocol` |
