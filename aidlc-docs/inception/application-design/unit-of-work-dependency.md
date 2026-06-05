# Unit of Work Dependencies — HeartRateCoach

## Dependency Matrix

| Unit | Depends On | Reason |
|---|---|---|
| Unit 1 — HeartRateCoachCore | — | Pure Swift; no external dependencies |
| Unit 2 — iPhone Foundation | Unit 1 | Imports `HeartRateCoachCore` for `UserProfile`, `HRZones`, `WorkoutProgram`, `Session` |
| Unit 3 — iPhone Workout Engine | Unit 1, Unit 2 | Uses Core models + Unit 2 services (`FirebaseService`, `OfflineSessionQueue`) |
| Unit 4 — Apple Watch App | Unit 1 | Imports `HeartRateCoachCore` for `HRReading`, `CoachingCommand`, `HapticPattern` |

## External Dependencies (SPM — Firebase iOS SDK)

| Package | Used By | Purpose |
|---|---|---|
| `FirebaseAuth` | Unit 2 | Sign in with Apple authentication |
| `FirebaseFirestore` | Unit 2, Unit 3 | Firestore read/write |
| `FirebaseFirestoreSwift` | Unit 2, Unit 3 | Codable support for Firestore documents |

## Framework Dependencies (Apple — no SPM required)

| Framework | Used By | Purpose |
|---|---|---|
| `AuthenticationServices` | Unit 2 | `ASAuthorizationAppleIDCredential` |
| `HealthKit` | Unit 2, Unit 4 | Authorization (Unit 2); `HKWorkoutSession` (Unit 4) |
| `WatchConnectivity` | Unit 3, Unit 4 | `WCSession` iPhone side (Unit 3); Watch side (Unit 4) |
| `AVFoundation` | Unit 3 | `AVSpeechSynthesizer` for voice coaching |
| `WatchKit` | Unit 4 | `WKInterfaceDevice` haptics |
| `CoreData` | Unit 2 | `OfflineSessionQueue` local persistence |
| `Network` | Unit 2 | `NWPathMonitor` for connectivity detection |

## Build Order Constraints

```
Unit 1 must compile before Unit 2, Unit 3, Unit 4

Unit 2 must compile before Unit 3

Unit 4 has no dependency on Unit 2 or Unit 3
  (only needs Unit 1 + WatchKit + HealthKit + WatchConnectivity)
```

## Shared Protocols (defined in Unit 2, consumed in Unit 3)

Unit 3 depends on these protocols defined in Unit 2:

| Protocol | Defined In | Used By |
|---|---|---|
| `FirebaseServiceProtocol` | Unit 2 | Unit 3 — `WorkoutSessionManager`, `HistoryViewModel` |
| `OfflineSessionQueueProtocol` | Unit 2 | Unit 3 — `WorkoutSessionManager` |
| `HealthKitServiceProtocol` | Unit 2 | Unit 2 — `OnboardingViewModel` |
| `AuthServiceProtocol` | Unit 2 | Unit 2 — `AppContainer` |

## Test Dependencies

| Unit | Test Target | Test Dependencies |
|---|---|---|
| Unit 1 | `HeartRateCoachCoreTests` | XCTest + PBT framework (swift-gen or SwiftCheck) |
| Unit 2 | `HeartRateCoachTests` | XCTest + Mock implementations of Unit 2 protocols |
| Unit 3 | `HeartRateCoachTests` | XCTest + Mocks for all service protocols |
| Unit 4 | `HeartRateCoachWatchTests` | XCTest + Mock `WatchConnectivityManager` |
