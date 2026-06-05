# Components — HeartRateCoach

## Architecture Decisions Applied
- **UI Pattern**: MVVM — `@Observable` ViewModels, declarative SwiftUI Views
- **CoachingEngine**: Per-session instance — created on workout start, released on end
- **Reactive Flow**: Combine for HR/coaching streams; async/await for Firebase operations
- **Dependency Injection**: Constructor injection throughout; protocols for all services

---

## Unit 1: HeartRateCoachCore (Local SPM Package)

Pure Swift — no UIKit, SwiftUI, HealthKit, or Firebase. Fully unit-testable.

### UserProfile
**Responsibility**: Represents the user's physiological and preference data.
- Holds: `age`, `restingHR`, `sex?`, `weight?`, `goal`, `preferredWorkout`
- Value type (`struct`) — immutable snapshot of user data

### HRZones
**Responsibility**: Stores the five calculated heart rate zone boundaries.
- Holds five `Zone` values, each with `min` and `max` bpm
- Value type (`struct`) — derived from `ZoneCalculator`, stored in Firestore

### WorkoutProgram
**Responsibility**: Defines the complete phase sequence for one of the three workout types.
- Enum cases: `.continuous`, `.hiit`, `.fartlek`
- Each case provides its ordered `[WorkoutPhase]` sequence

### WorkoutPhase
**Responsibility**: Represents a single timed segment within a workout program.
- Holds: `duration` (seconds), `targetZone` (1–5 or nil for recovery), `type` (warmup / exercise / recovery / cooldown), `hasGracePeriod` (Bool)
- Value type (`struct`)

### Session
**Responsibility**: Immutable record of a completed workout session.
- Holds: `id`, `date`, `programType`, `durationSec`, `avgHR`, `timeInZones` (dictionary), `hrStream` ([HRRecord])
- Value type (`struct`)

### HRRecord
**Responsibility**: Single HR data point within a session's time-series.
- Holds: `timestamp`, `second`, `hr`, `currentZone`, `targetZone`, `phase`, `coachingMessage?`
- Value type (`struct`)

### ZoneCalculator
**Responsibility**: Computes HR zones from age and resting HR using the Karvonen formula. Also classifies a given HR into a zone number.
- Static methods only — no state
- Primary target for property-based testing (PBT-02, PBT-03)

### WorkoutPhaseSequencer
**Responsibility**: Iterates through a `WorkoutProgram`'s phase sequence, tracking elapsed time and providing the current phase.
- Stateful — advances phases as time elapses
- Used by `CoachingEngine` to know which phase is active

---

## Unit 2: iPhone Foundation

### AuthService
**Responsibility**: Manages Firebase Auth lifecycle — Sign in with Apple, sign-out, current user state.
- Conforms to `AuthServiceProtocol`
- Publishes `currentUser: AnyPublisher<FirebaseUser?, Never>`

### FirebaseService
**Responsibility**: All Firestore read/write operations for user profile, zones, settings, sessions, and emergency events.
- Conforms to `FirebaseServiceProtocol`
- All operations are `async throws`
- Scopes all reads/writes to the authenticated user's document tree

### HealthKitService
**Responsibility**: Requests HealthKit authorization for heart rate data reading.
- Conforms to `HealthKitServiceProtocol`
- Authorization is requested once; result is cached

### OfflineSessionQueue
**Responsibility**: Persists completed sessions locally when Firebase is unreachable; flushes them when connectivity is restored.
- Backed by Core Data or UserDefaults
- Conforms to `OfflineSessionQueueProtocol`

### OnboardingViewModel (`@Observable`)
**Responsibility**: Manages state for the multi-step onboarding flow — input validation, zone preview, profile save.
- Receives: `FirebaseService`, `HealthKitService` via constructor injection

### SettingsViewModel (`@Observable`)
**Responsibility**: Manages state for the Settings screen — profile editing, zone recalculation on save.
- Receives: `FirebaseService` via constructor injection

### ZoneDisplayViewModel (`@Observable`)
**Responsibility**: Formats HR zone data for display (bpm ranges, zone names, labels).
- Pure transformation — no service dependencies

---

## Unit 3: iPhone Workout Engine

### CoachingEngine
**Responsibility**: Orchestrates all three coaching layers for the duration of a workout. Consumes HR readings, applies Safety / Zone Coaching / Positive Feedback layers, publishes `CoachingState` updates.
- Per-session instance — created fresh for each workout
- Receives: `WorkoutProgram`, `HRZones`, `VoiceFeedbackService`, `WatchBridge` via constructor
- Publishes: `coachingStatePublisher: AnyPublisher<CoachingState, Never>` (Combine)

### SafetyMonitor
**Responsibility**: Layer 1 — checks every HR reading against HRmax. Triggers emergency stop if exceeded.
- Used internally by `CoachingEngine`
- Stateless between calls

### ZoneCoach
**Responsibility**: Layer 2 — smooths HR over last 2–3 readings, evaluates against target zone, enforces 20-second anti-spam rule.
- Used internally by `CoachingEngine`
- Holds anti-spam state and HR smoothing buffer

### PositiveFeedbackCoach
**Responsibility**: Layer 3 — tracks continuous time in target zone; triggers "Good job" cue at 30-second mark.
- Used internally by `CoachingEngine`
- Holds in-zone streak timer

### VoiceFeedbackService
**Responsibility**: Delivers voice coaching cues via `AVSpeechSynthesizer`.
- Conforms to `VoiceFeedbackProtocol`
- Queues utterances; avoids overlapping speech

### WatchBridge
**Responsibility**: WatchConnectivity interface — sends haptic commands to Watch, receives HR readings from Watch.
- Conforms to `WatchBridgeProtocol`
- Publishes: `hrReadingsPublisher: AnyPublisher<HRReading, Never>` (Combine)

### WorkoutSessionManager
**Responsibility**: Orchestrates the full workout lifecycle on iPhone — creates `CoachingEngine`, subscribes to HR stream, writes `HRRecord` entries to Firebase every 5 sec, saves completed session on stop, hands off to `OfflineSessionQueue` if Firebase unavailable.
- Conforms to `WorkoutSessionManagerProtocol`
- Coordinates between `CoachingEngine`, `WatchBridge`, `FirebaseService`, `OfflineSessionQueue`

### WorkoutViewModel (`@Observable`)
**Responsibility**: Drives the Workout Active screen — exposes live HR, zone, phase timer, coaching message, elapsed time.
- Receives: `WorkoutSessionManager` via constructor injection
- Subscribes to `CoachingEngine.coachingStatePublisher` via Combine

### SessionSummaryViewModel (`@Observable`)
**Responsibility**: Formats a completed `Session` for the Session Summary screen.
- Pure transformation — receives a `Session` value, no service dependencies

### HistoryViewModel (`@Observable`)
**Responsibility**: Loads and displays the list of past sessions from Firestore.
- Receives: `FirebaseService` via constructor injection
- Loads sessions via `async/await`

---

## Unit 4: Apple Watch App

### WatchSessionManager
**Responsibility**: Manages `HKWorkoutSession` on the Watch — starts/stops the workout, reads live HR from HealthKit sensor every 5 seconds.
- Conforms to `WatchSessionManagerProtocol`

### WatchConnectivityManager
**Responsibility**: WatchConnectivity interface on the Watch side — sends HR readings to iPhone via `sendMessage`, receives coaching commands (haptic instructions) in the reply handler.

### HapticManager
**Responsibility**: Executes haptic patterns on the Watch via `WKInterfaceDevice.current().play(_:)`.
- Maps `HapticPattern` enum to `WKHapticType`

### WorkoutWatchViewModel (`@Observable`)
**Responsibility**: Drives the Watch Workout Active screen — exposes live HR, current zone, target zone, phase indicator, coaching overlay state.
- Receives coaching commands from `WatchConnectivityManager`
