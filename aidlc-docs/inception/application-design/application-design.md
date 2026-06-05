# Application Design — HeartRateCoach (Consolidated)

## Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| UI Pattern | MVVM with `@Observable` | Clean separation, testable ViewModels, suits real-time state updates |
| CoachingEngine lifecycle | Per-session instance | Clean state reset, no residual state between sessions, easier to test |
| Reactive data flow | Mixed — Combine (HR/coaching streams) + async/await (Firebase) | Right tool for each job; continuous streams → Combine, one-shot async → async/await |
| Dependency injection | Constructor injection | Explicit dependencies, compile-time safety, mock-friendly for unit tests |
| Shared code | Local SPM package (`HeartRateCoachCore`) | Clean separation of pure logic from platform-specific code |

---

## System Overview

HeartRateCoach is a three-target Xcode project with a shared local Swift Package:

```
HeartRateCoach (Xcode Workspace)
  |
  +-- HeartRateCoachCore/          Local SPM Package
  |     Pure Swift: models, ZoneCalculator, WorkoutProgram definitions
  |     No UIKit / HealthKit / Firebase dependencies
  |
  +-- HeartRateCoach/              iPhone App Target (iOS 17+)
  |     Foundation: Auth, Onboarding, Settings, Firebase profile
  |     Workout Engine: CoachingEngine, WatchBridge, WorkoutSessionManager
  |     Views: SwiftUI screens (MVVM)
  |
  +-- HeartRateCoachWatch/         watchOS App Target (watchOS 10+)
        Watch-side: HKWorkoutSession, WatchConnectivity, Haptics
        Views: Watch screens (MVVM)
```

---

## Component Inventory

### HeartRateCoachCore (SPM)
| Component | Type | Responsibility |
|---|---|---|
| `UserProfile` | struct | User physiological + preference data |
| `HRZones` | struct | Five Karvonen-calculated zone boundaries |
| `WorkoutProgram` | enum | Defines Continuous / HIIT / Fartlek phase sequences |
| `WorkoutPhase` | struct | Single timed segment (duration, zone, type, grace period flag) |
| `Session` | struct | Completed workout record |
| `HRRecord` | struct | Single HR time-series data point |
| `ZoneCalculator` | struct (static) | Karvonen formula; zone classification |
| `WorkoutPhaseSequencer` | struct | Iterates through program phases by elapsed time |

### iPhone — Services
| Component | Type | Responsibility |
|---|---|---|
| `AuthService` | class | Firebase Auth + Sign in with Apple |
| `FirebaseService` | class | All Firestore read/write |
| `HealthKitService` | class | HealthKit authorization |
| `OfflineSessionQueue` | class | Core Data queue + auto-sync on reconnect |
| `WatchBridge` | class | WatchConnectivity iPhone side |
| `VoiceFeedbackService` | class | AVSpeechSynthesizer wrapper |

### iPhone — Coaching Engine
| Component | Type | Responsibility |
|---|---|---|
| `CoachingEngine` | class (per-session) | Orchestrates all 3 coaching layers |
| `SafetyMonitor` | struct | Layer 1 — HR > HRmax detection |
| `ZoneCoach` | class | Layer 2 — zone feedback + anti-spam |
| `PositiveFeedbackCoach` | class | Layer 3 — 30s in-zone reward |
| `WorkoutSessionManager` | class | Workout lifecycle, Firebase writes, offline fallback |

### iPhone — ViewModels
| Component | Type | Screen |
|---|---|---|
| `OnboardingViewModel` | @Observable class | Onboarding |
| `SettingsViewModel` | @Observable class | Settings |
| `ZoneDisplayViewModel` | @Observable class | Zone preview (Onboarding + Settings) |
| `WorkoutViewModel` | @Observable class | Workout Active |
| `SessionSummaryViewModel` | @Observable class | Session Summary |
| `HistoryViewModel` | @Observable class | History |

### Apple Watch App
| Component | Type | Responsibility |
|---|---|---|
| `WatchSessionManager` | class | HKWorkoutSession on Watch |
| `WatchConnectivityManager` | class | WatchConnectivity Watch side |
| `HapticManager` | struct | WKHapticType execution |
| `WorkoutWatchViewModel` | @Observable class | Watch Workout Active + Coaching Overlay + Emergency Stop |

---

## Key Design Patterns

### Protocol-Based Services
Every external service is defined as a protocol. Concrete implementations are created once in `AppContainer` and injected via constructors. Test doubles conform to the same protocols.

```
FirebaseServiceProtocol <-- FirebaseService (production)
                        <-- MockFirebaseService (tests)
```

### Coaching Engine Data Flow
```
WatchBridge (Combine publisher)
  → CoachingEngine.processReading()
    → SafetyMonitor      [every 5 sec]
    → ZoneCoach          [every 10 sec, with anti-spam]
    → PositiveFeedbackCoach [condition-based]
  → coachingStatePublisher (Combine)
    → WorkoutViewModel (@Observable)
      → WorkoutView (SwiftUI)
```

### Offline Session Handling
```
WorkoutSessionManager.stopWorkout()
  → FirebaseService.saveSession() [async throws]
    success → SyncStatus.synced
    failure → OfflineSessionQueue.enqueue()
                → NWPathMonitor detects reconnect
                  → OfflineSessionQueue.flush() [async]
```

### Watch ↔ iPhone Round-Trip
```
Watch: HKWorkoutSession → HR reading
  → WatchConnectivityManager.sendHRReading()
    → WCSession.sendMessage(hr, replyHandler:)
      → iPhone: WatchBridge receives message
        → hrReadingsPublisher emits
          → CoachingEngine processes
            → coaching command determined
              → reply handler sends CoachingCommand back
                → Watch: WatchConnectivityManager receives reply
                  → HapticManager.play()
```

---

## Security Design Notes (SECURITY-11)

- `CoachingEngine`, `ZoneCalculator`, and `SafetyMonitor` are isolated from all authentication, storage, and network concerns
- `FirebaseService` is the single boundary for all Firestore operations — no other component writes directly to Firestore
- `AuthService` is the single boundary for all authentication operations
- Health data (HR readings) flows through the app in memory only; persisted to Firestore under the authenticated user's UID with Firebase Security Rules enforcing ownership
- No HR data or user credentials appear in log output (SECURITY-03)

---

## Detailed Documents

- [components.md](components.md) — full component descriptions and responsibilities
- [component-methods.md](component-methods.md) — method signatures for all components
- [services.md](services.md) — service protocols, interaction patterns, data flow diagrams
- [component-dependency.md](component-dependency.md) — dependency matrix, unit ordering, data flow sequences
