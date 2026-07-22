# Logical Components — Unit 3: iPhone Workout Engine

## Component Map

```
HeartRateCoachCore (Unit 1 SPM package — extended by Unit 3)
  └── CoachingEngineState (struct)        ← NEW in Unit 3
  └── CoachingEngine (enum, static tick)  ← NEW in Unit 3

HeartCoach (iPhone app target)
  └── WorkoutSessionManager               ← NEW: owns state, drives loop
      ├── VoiceFeedbackService            ← NEW: AVSpeechSynthesizer wrapper
      ├── WatchBridge                     ← NEW: WCSession wrapper
      └── WorkoutPhaseSequencer           ← Unit 1, owned per-session
  └── WorkoutViewModel                    ← NEW: @Observable, MainActor
  └── WorkoutSummaryViewModel             ← NEW: @Observable
  └── HistoryViewModel                    ← NEW: @Observable
```

---

## CoachingEngineState

**Package**: `HeartRateCoachCore` (shared domain layer)
**Type**: `struct` (value type)
**Responsibility**: All mutable state the coaching engine reads and writes between ticks.

| Property | Type | Initial Value | Purpose |
|---|---|---|---|
| `hrBuffer` | `[Int]` | `[]` | Last 2 raw HR readings; averaged to `hrSmooth` |
| `lastLayer2MessageAt` | `Date?` | `nil` | Anti-spam: Layer 2 minimum gap 20s |
| `consecutiveInZoneSeconds` | `TimeInterval` | `0` | Layer 3 counter; fires at ≥30s |

**Computed property**:
```swift
var hrSmooth: Int {
    guard !hrBuffer.isEmpty else { return 0 }
    return Int(ceil(Double(hrBuffer.reduce(0, +)) / Double(hrBuffer.count)))
}
```

**Reset on pause**:
- `consecutiveInZoneSeconds = 0` — streak is broken
- `lastLayer2MessageAt = nil` — coaching resumes promptly after resume

---

## CoachingEngine

**Package**: `HeartRateCoachCore` (shared domain layer)
**Type**: `enum` (namespace for static functions; cannot be instantiated)
**Responsibility**: Pure coaching logic. Receives current HR, phase, elapsed time, and state; returns one optional coaching message and mutates state.

**Signature**:
```swift
enum CoachingEngine {
    static func tick(
        hr: Int,
        phase: WorkoutPhase,
        elapsedInPhase: TimeInterval,
        state: inout CoachingEngineState,
        zones: HRZones,
        now: Date = Date()
    ) -> CoachingMessage?
}
```

**Layer evaluation order** (mutual exclusion via early return):
1. Update `hrBuffer`, compute `hrSmooth`
2. **Layer 1 Safety** — if `hrSmooth > zones.zone5.max` → return `.emergencyStop`; if `hrSmooth > zones.zone5.max * 0.97` (near-max) → return `.slowDown` (exact thresholds per business-rules.md)
3. **Layer 2 Zone Coaching** — if phase has target zone, grace period has passed, anti-spam gap met → evaluate zone and return message
4. **Layer 3 Positive Feedback** — if `consecutiveInZoneSeconds >= 30` → return `.keepItUp`
5. Return `nil` (silent tick)

**Dependencies**: `HRZones`, `WorkoutPhase`, `CoachingEngineState` (all from Unit 1)
**No dependencies on**: UIKit, AVFoundation, WatchConnectivity, Firebase

---

## WorkoutSessionManager

**Target**: `HeartCoach` (iPhone app)
**Type**: `final class` (reference type — owns resources, Task, WCSession delegate)
**Responsibility**: Orchestrates a single workout session. Owns the tick loop, state, HR receipt, phase sequencing, and bridges to voice and Watch.

| Responsibility | Detail |
|---|---|
| Tick loop | `Task` + `Task.sleep(5s)`; cancel on pause; recreate on resume |
| State ownership | Holds `CoachingEngineState` value; passes as `inout` to `tick()` |
| HR staleness | Tracks `lastHRReceived: HRReading`; computes staleness each tick |
| Phase sequencing | Owns `WorkoutPhaseSequencer`; advances on phase timeout |
| Voice dispatch | Calls `VoiceFeedbackService.speak()` with `CoachingMessage` result |
| Haptic dispatch | Calls `WatchBridge.sendHaptic()` on Layer 1 messages |
| UI update | Publishes `CoachingState` snapshot to `WorkoutViewModel` on `@MainActor` |
| Session recording | Accumulates `HRRecord` array; builds `Session` on workout end |

**Lifecycle**: Created fresh per workout session (one-shot use). Torn down on workout end, pause-to-abandon, or emergency stop.

**Key methods**:
```swift
func start(program: WorkoutProgram, profile: UserProfile, zones: HRZones)
func pause()
func resume()
func end() async -> Session
func emergencyStop()
```

---

## VoiceFeedbackService

**Target**: `HeartCoach`
**Type**: `final class`
**Responsibility**: Wraps `AVSpeechSynthesizer`. Translates `CoachingMessage` → spoken English text.

| Responsibility | Detail |
|---|---|
| Audio session | Configures `.playback` + `.duckOthers` + `.allowBluetooth` at workout start |
| Voice selection | `AVSpeechSynthesisVoice(language: "en-US")` — always English regardless of device locale |
| Interruption | `stopSpeaking(at: .immediate)` before every utterance |
| Mute bypass | Layer 1 messages always spoken; Layer 2 and 3 check mute preference |
| Message text | `CoachingMessage` carries its spoken text string; service does not generate text |

**Protocol** (`VoiceFeedbackServiceProtocol`):
```swift
protocol VoiceFeedbackServiceProtocol {
    var isMuted: Bool { get set }
    func speak(_ message: CoachingMessage)
    func stopSpeaking()
    func configureAudioSession()
}
```

---

## WatchBridge

**Target**: `HeartCoach`
**Type**: `final class` + `WCSessionDelegate`
**Responsibility**: Manages all iPhone ↔ Watch communication during a workout.

| Direction | Data | Method |
|---|---|---|
| Watch → iPhone | HR readings (`HRReading`) | `session(_:didReceiveMessage:)` delegate |
| iPhone → Watch | Haptic commands (`HapticPattern`) | `sendMessage(_:replyHandler:errorHandler:)` |

**HR receipt**: Received on background queue → dispatched to `WorkoutSessionManager` on `@MainActor` to update `lastHRReceived`.

**Haptic sending**: Fire-and-forget. `errorHandler` silently discards. No retry.

**Protocol** (`WatchBridgeProtocol`):
```swift
protocol WatchBridgeProtocol {
    var onHRReceived: ((HRReading) -> Void)? { get set }
    func sendHaptic(_ pattern: HapticPattern)
    func activate()
    func deactivate()
}
```

---

## WorkoutViewModel

**Target**: `HeartCoach`
**Type**: `@Observable final class`
**Responsibility**: Observable snapshot of the live workout state for `WorkoutView`. Updated on `@MainActor` by `WorkoutSessionManager`.

| Property | Type | Source |
|---|---|---|
| `coachingState` | `CoachingState` | Published by `WorkoutSessionManager` each tick |
| `activePhase` | `WorkoutPhase?` | Current phase from `WorkoutPhaseSequencer` |
| `elapsedTime` | `TimeInterval` | Wall-clock timer from session start |
| `isPaused` | `Bool` | Pause state |
| `lastMessage` | `CoachingMessage?` | Most recent coaching message (for on-screen display) |

**Actions**:
```swift
func pause()
func resume()
func end() async
func emergencyStop()
```

---

## WorkoutSummaryViewModel

**Target**: `HeartCoach`
**Type**: `@Observable final class`
**Responsibility**: Computes and displays post-workout summary from a completed `Session`.

| Property | Source |
|---|---|
| `session` | `Session` passed from `WorkoutSessionManager.end()` |
| `avgHR` | Computed from `session.hrRecords` |
| `timePerZone` | Computed from `hrRecords` — seconds spent in each of 5 zones |
| `peakHR` | `session.hrRecords.map(\.value).max()` |
| `saveState` | `.idle` / `.saving` / `.saved` / `.failed` |

**Action**: `saveSession()` — calls `FirestoreService.saveSession(session, userID:)` via `AppContainer`.

---

## HistoryViewModel

**Target**: `HeartCoach`
**Type**: `@Observable final class`
**Responsibility**: Loads and displays the list of past sessions.

| Property | Source |
|---|---|
| `sessions` | `FirestoreService.loadSessions(userID:limit:)` |
| `isLoading` | Loading state |
| `error` | `AppError?` on failure |

**Pagination**: `loadMore()` increases limit by 10 per call (lazy loading).

---

## Component Interaction Diagram

```
WatchBridge ──HR──► WorkoutSessionManager ──tick()──► CoachingEngine (static)
                           │                                  │
                           │ state: inout CoachingEngineState ◄┘
                           │
                           ├──► VoiceFeedbackService.speak()
                           ├──► WatchBridge.sendHaptic()
                           └──► MainActor.run { workoutVM.coachingState = ... }

WorkoutViewModel ◄──── @Observable ──── WorkoutView
```

---

## Unit → Package Mapping

| Component | Package / Target |
|---|---|
| `CoachingEngineState` | `HeartRateCoachCore` (SPM) |
| `CoachingEngine` | `HeartRateCoachCore` (SPM) |
| `WorkoutSessionManager` | `HeartCoach` app target |
| `VoiceFeedbackService` | `HeartCoach` app target |
| `WatchBridge` | `HeartCoach` app target |
| `WorkoutViewModel` | `HeartCoach` app target |
| `WorkoutSummaryViewModel` | `HeartCoach` app target |
| `HistoryViewModel` | `HeartCoach` app target |

`CoachingEngineState` and `CoachingEngine` live in the shared SPM package so the Apple Watch app (Unit 4) can reuse the same logic without duplicating it.
