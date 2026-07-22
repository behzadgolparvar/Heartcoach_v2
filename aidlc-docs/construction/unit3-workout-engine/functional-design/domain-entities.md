# Domain Entities — Unit 3: iPhone Workout Engine

Unit 3 imports all models from `HeartRateCoachCore` (Unit 1) and services from Unit 2. This document defines the additional types introduced in Unit 3.

---

## ActiveWorkoutState (enum)

Tracks the lifecycle of a running workout session. Managed by `WorkoutSessionManager`.

| Case | Description |
|---|---|
| `.idle` | No workout running |
| `.preStart(WorkoutProgram)` | Pre-start screen — program selected, not yet started |
| `.active` | Workout running, coaching active |
| `.paused` | Timer frozen, Watch paused, coaching frozen |
| `.complete(Session)` | All phases done — summary screen shown |
| `.emergencyStopped` | HR exceeded HRmax — full-screen alert shown |

---

## CoachingLayer (enum)

Identifies which coaching layer produced a message. Used to determine haptic pattern and voice priority.

| Case | Description |
|---|---|
| `.safety` | Layer 1 — HR signal lost or above HRmax |
| `.zoneCoaching` | Layer 2 — HR below or above target zone |
| `.positiveFeedback` | Layer 3 — 30 consecutive seconds in-zone |

---

## CoachingMessage (struct)

A single coaching output event, produced by `CoachingEngine` and consumed by `WorkoutViewModel` and `VoiceFeedbackService`.

| Property | Type | Description |
|---|---|---|
| `text` | `String` | Human-readable message (e.g. "Speed up", "Great work!") |
| `layer` | `CoachingLayer` | Which layer produced this message |
| `haptic` | `HapticPattern?` | Haptic to send to Watch; nil for safety banner |
| `timestamp` | `Date` | When the message was generated |

---

## CoachingEngineState (struct)

Internal mutable state of the `CoachingEngine`. Passed between ticks.

| Property | Type | Description |
|---|---|---|
| `hrBuffer` | `[Int]` | Last 2 HR readings for smoothing |
| `hrSmooth` | `Int` | Averaged HR from buffer |
| `lastLayer2MessageAt` | `Date?` | Timestamp of last Layer 2 cue (anti-spam) |
| `consecutiveInZoneSeconds` | `Double` | Running count of seconds in target zone |
| `lastLayer3MessageAt` | `Date?` | Timestamp of last Layer 3 positive feedback |

---

## WorkoutSessionManager (@Observable class)

Owns the full workout lifecycle. One instance per app session (not per workout — it resets between workouts).

| Property | Type | Description |
|---|---|---|
| `state` | `ActiveWorkoutState` | Current lifecycle state |
| `sequencer` | `WorkoutPhaseSequencer?` | Phase iterator; non-nil during `.active` / `.paused` |
| `elapsedSeconds` | `Double` | Total active (non-paused) elapsed time |
| `hrStream` | `[HRRecord]` | Accumulates HR records every 5 seconds |
| `selectedProgram` | `WorkoutProgram?` | Program for the current/upcoming workout |

Key methods: `selectProgram(_:)`, `start(userID:zones:)`, `pause()`, `resume()`, `end()`, `emergencyStop()`

---

## CoachingEngine (class — per-session instance)

Created fresh when a workout starts. Destroyed when the session ends. Receives HR readings and emits `CoachingMessage` events.

| Property | Type | Description |
|---|---|---|
| `zones` | `HRZones` | User's personalised zones — immutable for session |
| `state` | `CoachingEngineState` | Mutable tick state |

Key methods:
- `tick(hr: Int, phase: WorkoutPhase, elapsedInPhase: TimeInterval) -> CoachingMessage?`
- Called every 5 seconds by `WorkoutSessionManager`

---

## VoiceFeedbackService (class)

Wraps `AVSpeechSynthesizer`. Speaks coaching messages. Can be muted via a toggle.

| Property | Type | Description |
|---|---|---|
| `isMuted` | `Bool` | If true, speech is suppressed; haptics still fire |

Key methods: `speak(_ message: CoachingMessage)`

---

## WatchBridge (class — Unit 3 iPhone side)

Sends commands to Watch and receives HR readings from Watch via `WCSession`.

Key methods:
- `send(_ command: CoachingCommand)` — sends haptic/overlay commands to Watch
- HR readings received via `WCSessionDelegate.didReceiveMessage` → published to `WorkoutSessionManager`

---

## WorkoutViewModel (@Observable)

Drives the live workout screen. Observes `WorkoutSessionManager` and `CoachingEngine` output.

| Property | Type | Description |
|---|---|---|
| `currentHR` | `Int` | Latest raw HR from Watch |
| `hrSmooth` | `Int` | Smoothed HR (2-reading average) |
| `currentZone` | `Int` | Zone user is currently in |
| `targetZone` | `Int?` | Zone required by current phase |
| `phase` | `PhaseType` | Current phase type |
| `phaseTimeRemaining` | `TimeInterval` | Seconds left in current phase |
| `elapsedTime` | `TimeInterval` | Total active time |
| `coachingMessage` | `String?` | Last coaching cue text |
| `isGracePeriodActive` | `Bool` | True if coaching suppressed |
| `workoutState` | `ActiveWorkoutState` | Forwarded from `WorkoutSessionManager` |

---

## WorkoutSummaryViewModel (@Observable)

Computed summary data from a completed `Session`.

| Property | Type | Description |
|---|---|---|
| `session` | `Session` | The completed session |
| `maxHR` | `Int` | Peak HR during the session |
| `zoneMinutes` | `[Int: Int]` | Zone → minutes (computed from `timeInZones`) |
| `isSaving` | `Bool` | True while Firestore write is in progress |
| `saveError` | `String?` | Error message if save failed |

---

## HistoryViewModel (@Observable)

Loads and displays the full session history list.

| Property | Type | Description |
|---|---|---|
| `sessions` | `[Session]` | All loaded sessions, sorted by date descending |
| `isLoading` | `Bool` | True while Firestore query is in progress |
| `selectedSession` | `Session?` | Session tapped for detail view |
