# Services — HeartRateCoach

## Service Layer Overview

Services are the boundary between the application's business logic and external systems (Firebase, HealthKit, WatchConnectivity, AVFoundation). Each service:
- Conforms to a protocol (enabling constructor injection and mock substitution in tests)
- Has a single, clear external system responsibility
- Does not contain business logic — that lives in components (CoachingEngine, ZoneCalculator)

---

## Service Protocols

All services are defined as protocols first. The concrete implementations are injected at app startup via the `AppContainer` (the composition root).

```swift
protocol FirebaseServiceProtocol { ... }
protocol HealthKitServiceProtocol { ... }
protocol WatchBridgeProtocol { ... }
protocol VoiceFeedbackProtocol { ... }
protocol OfflineSessionQueueProtocol { ... }
protocol AuthServiceProtocol { ... }
protocol WorkoutSessionManagerProtocol { ... }
```

---

## AppContainer (Composition Root)

**Responsibility**: Creates all concrete service instances at app launch and injects them into ViewModels. Lives in `HeartRateCoachApp.swift`. Never passes services through `@EnvironmentObject` — always through constructors.

```
AppContainer
  ├── AuthService (concrete)
  ├── FirebaseService (concrete, depends on Auth)
  ├── HealthKitService (concrete)
  ├── WatchBridge (concrete)
  ├── VoiceFeedbackService (concrete)
  ├── OfflineSessionQueue (concrete)
  └── WorkoutSessionManager (concrete, depends on above)
```

At test time, any concrete implementation can be replaced with a mock that conforms to the same protocol.

---

## Service Descriptions

### AuthService
**External System**: Firebase Auth + Sign in with Apple (`AuthenticationServices`)
**Responsibility**: Authenticates the user; provides the current authenticated user ID used to scope all Firestore paths
**Interaction Pattern**: Async — `async throws` methods; Combine publisher for auth state changes
**Error Handling**: Throws `AuthError` on sign-in failure; publishes `nil` user on sign-out

---

### FirebaseService
**External System**: Firebase Cloud Firestore
**Responsibility**: All read/write operations for user data (`users/{uid}/...`) and session data (`users/{uid}/sessions/...`). Scopes every operation to the authenticated UID from `AuthService`.
**Interaction Pattern**: Async — all methods are `async throws`
**Error Handling**: Throws `FirebaseError`; callers (e.g. `WorkoutSessionManager`) catch and hand off to `OfflineSessionQueue` when appropriate
**Security**: All Firestore paths include the authenticated user's UID; Firebase Security Rules enforce server-side that users can only read/write their own data

---

### HealthKitService
**External System**: Apple HealthKit framework
**Responsibility**: Requests HealthKit authorization for HR reading. Does NOT read HR during workouts — that is handled by `WatchSessionManager` on the Watch via `HKWorkoutSession`.
**Interaction Pattern**: Async — `async throws` for authorization request
**Note**: Authorization is a one-time prompt on first launch; subsequent calls check cached status

---

### WatchBridge (iPhone side)
**External System**: WatchConnectivity (`WCSession`)
**Responsibility**: iPhone-side WatchConnectivity — receives HR readings from Watch, sends coaching commands (haptic patterns, workout start/stop signals, emergency stop) back to Watch
**Interaction Pattern**:
- Incoming HR readings: Combine publisher (`hrReadingsPublisher`)
- Outgoing commands: fire-and-forget (no await needed for haptics)
**Reconnection**: Detects Watch reachability changes and publishes via `isConnectedPublisher`

---

### VoiceFeedbackService
**External System**: AVFoundation (`AVSpeechSynthesizer`)
**Responsibility**: Converts coaching text into spoken audio on iPhone; routes to AirPods/earphones if connected
**Interaction Pattern**: Synchronous enqueue — speech is queued internally; `AVSpeechSynthesizer` handles sequencing
**Anti-overlap**: Only one utterance plays at a time; new utterance cancels in-progress if it's a safety cue

---

### OfflineSessionQueue
**External System**: Core Data (local persistence)
**Responsibility**: Persists completed sessions locally when Firebase is unreachable; detects network reconnection and flushes queued sessions to Firestore
**Interaction Pattern**:
- Enqueue: synchronous
- Flush: `async` — calls `FirebaseService.saveSession(_:)` for each queued entry
**Sync trigger**: Monitors `NWPathMonitor` for network availability; auto-flushes when connection is restored
**Idempotency**: Each queued session has a local UUID; duplicate Firestore writes are prevented by checking if the session ID already exists before writing

---

## Service Interaction Map

```
App Startup
  AppContainer
    |
    +-- AuthService ---------> Firebase Auth
    |
    +-- FirebaseService ------> Firestore
    |       ^
    |       | uses UID from AuthService
    |
    +-- HealthKitService -----> HealthKit (auth only)
    |
    +-- WatchBridge ----------> WatchConnectivity (iPhone side)
    |       |
    |       | hrReadingsPublisher (Combine)
    |       v
    +-- WorkoutSessionManager
            |
            +-- creates CoachingEngine (per session)
            |       |
            |       +-- VoiceFeedbackService --> AVSpeechSynthesizer
            |       +-- WatchBridge (sends haptics)
            |
            +-- FirebaseService (async session writes)
            +-- OfflineSessionQueue (fallback on Firebase error)
```

---

## WatchConnectivity Service Pair

The `WatchBridge` (iPhone) and `WatchConnectivityManager` (Watch) form a matched pair:

| Direction | Data | Mechanism |
|---|---|---|
| Watch → iPhone | `HRReading` every 5 sec | `WCSession.sendMessage(_:replyHandler:)` |
| iPhone → Watch | `CoachingCommand` (haptic pattern) | Reply handler in `sendMessage` |
| iPhone → Watch | Workout start/stop, zone info | `WCSession.sendMessage(_:replyHandler:)` |
| iPhone → Watch | Emergency stop signal | `WCSession.sendMessage(_:replyHandler:)` |

The reply handler pattern ensures HR readings and coaching commands are coupled in the same round-trip, minimising latency.
