# Component Dependencies — HeartRateCoach

## Dependency Matrix

| Component | Depends On |
|---|---|
| `ZoneCalculator` | — (no dependencies) |
| `WorkoutPhaseSequencer` | `WorkoutProgram`, `WorkoutPhase` |
| `AuthService` | Firebase Auth SDK |
| `FirebaseService` | Firestore SDK, `AuthService` (for UID) |
| `HealthKitService` | HealthKit framework |
| `OfflineSessionQueue` | Core Data, `FirebaseServiceProtocol`, NWPathMonitor |
| `WatchBridge` (iPhone) | WatchConnectivity framework |
| `VoiceFeedbackService` | AVFoundation |
| `SafetyMonitor` | `HRZones`, `UserProfile` (for HRmax) |
| `ZoneCoach` | `HRZones`, `WorkoutPhase` |
| `PositiveFeedbackCoach` | `WorkoutPhase` |
| `CoachingEngine` | `WorkoutPhaseSequencer`, `SafetyMonitor`, `ZoneCoach`, `PositiveFeedbackCoach`, `VoiceFeedbackProtocol`, `WatchBridgeProtocol` |
| `WorkoutSessionManager` | `CoachingEngine`, `FirebaseServiceProtocol`, `WatchBridgeProtocol`, `OfflineSessionQueueProtocol`, `VoiceFeedbackProtocol` |
| `OnboardingViewModel` | `FirebaseServiceProtocol`, `HealthKitServiceProtocol`, `ZoneCalculator` |
| `SettingsViewModel` | `FirebaseServiceProtocol`, `ZoneCalculator` |
| `WorkoutViewModel` | `WorkoutSessionManagerProtocol` |
| `SessionSummaryViewModel` | `Session` (value type, no service dependency) |
| `HistoryViewModel` | `FirebaseServiceProtocol` |
| `WatchSessionManager` (Watch) | HealthKit (`HKWorkoutSession`) |
| `WatchConnectivityManager` (Watch) | WatchConnectivity framework |
| `HapticManager` | WatchKit (`WKInterfaceDevice`) |
| `WorkoutWatchViewModel` | `WatchConnectivityManager`, `HapticManager` |
| `AppContainer` | All concrete service implementations |

---

## Unit Dependency Ordering

Units must be built in this sequence due to import dependencies:

```
Unit 1: HeartRateCoachCore (SPM)
  No dependencies — pure Swift models and logic

Unit 2: iPhone Foundation
  Imports HeartRateCoachCore
  Adds: Auth, Firebase profile, HealthKit auth, OfflineQueue

Unit 4: Apple Watch App
  Imports HeartRateCoachCore
  Can be built in parallel with Unit 3

Unit 3: iPhone Workout Engine
  Imports HeartRateCoachCore
  Uses services from Unit 2 (FirebaseService, OfflineQueue)
  Provides: CoachingEngine, WatchBridge, WorkoutSessionManager
```

---

## Data Flow — Workout Execution

```
[Apple Watch]
  HKWorkoutSession
    |
    | HR reading (every 5 sec)
    v
  WatchConnectivityManager
    |
    | WCSession.sendMessage (HR data)
    v
[iPhone]
  WatchBridge.hrReadingsPublisher (Combine)
    |
    v
  CoachingEngine.processReading(_:)
    |
    +-- SafetyMonitor ---------> if HR > HRmax: emergency stop
    |                                |
    |                                +--> VoiceFeedbackService (safety cue)
    |                                +--> WatchBridge.notifyEmergencyStop()
    |                                +--> FirebaseService.saveEmergencyEvent()
    |
    +-- ZoneCoach (every 10 sec) -> if out of zone (anti-spam check):
    |                                +--> VoiceFeedbackService (speed up / slow down)
    |                                +--> WatchBridge.sendHaptic(_:)
    |
    +-- PositiveFeedbackCoach -> if 30s in zone:
    |                                +--> VoiceFeedbackService ("Good job")
    |                                +--> WatchBridge.sendHaptic(.doubleTap)
    |
    v
  CoachingEngine.coachingStatePublisher (Combine)
    |
    v
  WorkoutViewModel (updates @Observable properties)
    |
    v
  WorkoutView (SwiftUI — reacts to @Observable changes)

[Parallel — every 5 sec]
  WorkoutSessionManager
    |
    v
  FirebaseService.appendHRRecord(_:) [async, fire-and-forget]
```

---

## Data Flow — Session Save (Online)

```
WorkoutViewModel.confirmStopWorkout()
  |
  v
WorkoutSessionManager.stopWorkout() [async]
  |
  +-- CoachingEngine.stop() -> Session (value)
  |
  +-- FirebaseService.saveSession(_:) [async throws]
  |     |
  |     | success
  |     v
  |   SyncStatus.synced -> WorkoutViewModel shows no banner
  |     |
  |     | failure (network error)
  |     v
  +-- OfflineSessionQueue.enqueue(_:)
        |
        v
      WorkoutViewModel shows "Saved locally, pending sync" banner
```

---

## Data Flow — Offline Sync (Background)

```
OfflineSessionQueue (monitors NWPathMonitor)
  |
  | network becomes available
  v
OfflineSessionQueue.flush(using: firebaseService) [async]
  |
  +-- for each queued Session:
  |     FirebaseService.saveSession(_:) [async throws]
  |     on success: remove from local queue
  |
  v
SyncStatus.synced -> app shows "Session synced" confirmation
```

---

## Communication Patterns Summary

| Pattern | Used For | Components |
|---|---|---|
| Combine publisher | Continuous HR stream, coaching state, Watch connectivity | `WatchBridge`, `CoachingEngine`, `WorkoutSessionManager` → ViewModels |
| async/await | One-shot Firebase operations, HealthKit auth | All `FirebaseService` methods, `HealthKitService`, `OfflineSessionQueue.flush` |
| Constructor injection | All service-to-component wiring | `AppContainer` → all ViewModels and WorkoutSessionManager |
| Value types (structs) | All data passing between layers | `Session`, `HRZones`, `WorkoutPhase`, `HRRecord`, `UserProfile` |
| Protocol conformance | Test substitution | All services expose protocols; mocks used in unit tests |
