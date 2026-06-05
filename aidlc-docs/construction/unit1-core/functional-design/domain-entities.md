# Domain Entities — Unit 1: HeartRateCoachCore

All entities are **value types** (`struct`) unless noted. No UIKit, SwiftUI, HealthKit, or Firebase dependencies.

---

## UserProfile

Represents the user's physiological input and app preferences.

| Property | Type | Required | Description |
|---|---|---|---|
| `age` | `Int` | Yes | User age in years — used for HRmax calculation |
| `restingHR` | `Int` | Yes | Resting heart rate in bpm — used in Karvonen formula |
| `sex` | `Sex?` | No | Optional: `.male`, `.female`, `.other` |
| `weight` | `Double?` | No | Optional: weight in kg |
| `goal` | `Goal` | Yes | `.fatBurn` or `.endurance` |
| `preferredWorkout` | `WorkoutType` | Yes | `.continuous`, `.hiit`, `.fartlek` |

---

## HRZones

Stores all five calculated heart rate zone boundaries for a user.

| Property | Type | Description |
|---|---|---|
| `zone1` | `Zone` | Recovery — 50–60% HRR |
| `zone2` | `Zone` | Easy / Fat Burn — 60–70% HRR |
| `zone3` | `Zone` | Aerobic — 70–80% HRR |
| `zone4` | `Zone` | Threshold — 80–90% HRR |
| `zone5` | `Zone` | Max Effort — 90–100% HRR |

---

## Zone

Single heart rate zone boundary (used within `HRZones`).

| Property | Type | Description |
|---|---|---|
| `number` | `Int` | Zone number 1–5 |
| `name` | `String` | e.g. "Recovery", "Easy / Fat Burn" |
| `min` | `Int` | Lower boundary in bpm (inclusive) |
| `max` | `Int` | Upper boundary in bpm (exclusive — upper zone wins at exact boundary) |

---

## WorkoutProgram (enum)

Defines which of the three workout types is being run.

| Case | Description |
|---|---|
| `.continuous` | 5-cycle steady progressive effort |
| `.hiit` | 15-cycle high-intensity intervals |
| `.fartlek` | 15 varied 2-minute segments |

Each case provides `var phases: [WorkoutPhase]` — the complete ordered sequence for that program.

---

## WorkoutPhase

A single timed segment within a workout program.

| Property | Type | Description |
|---|---|---|
| `index` | `Int` | Position in the phase sequence (0-based) |
| `duration` | `TimeInterval` | Duration in seconds |
| `targetZone` | `Int?` | Target zone 1–5; `nil` for recovery phases (no HR enforcement) |
| `type` | `PhaseType` | `.warmup`, `.exercise`, `.recovery`, `.cooldown` |
| `hasGracePeriod` | `Bool` | `true` for HIIT and Fartlek exercise phases only |
| `instruction` | `String?` | Optional fixed coaching instruction (e.g. "Walk it out") for recovery phases |

---

## PhaseType (enum)

| Case | Description |
|---|---|
| `.warmup` | Opening warm-up segment |
| `.exercise` | Active training interval with target zone |
| `.recovery` | Rest/walking segment — no zone enforcement |
| `.cooldown` | Optional post-workout cool-down |

---

## Session

Immutable record of a completed workout.

| Property | Type | Description |
|---|---|---|
| `id` | `String` | Auto-generated UUID |
| `date` | `Date` | Workout start timestamp |
| `programType` | `WorkoutType` | Which program was run |
| `durationSec` | `Int` | Total duration in seconds |
| `avgHR` | `Int` | Simple mean of all HR readings |
| `timeInZones` | `[Int: Int]` | Zone number → seconds spent in that zone |
| `hrStream` | `[HRRecord]` | Full time-series of HR readings |

---

## HRRecord

A single HR data point within the session time-series.

| Property | Type | Description |
|---|---|---|
| `timestamp` | `Date` | Wall-clock time of reading |
| `second` | `Int` | Elapsed seconds since workout start |
| `hr` | `Int` | Raw HR reading from Watch sensor (bpm) |
| `currentZone` | `Int` | Zone the user is currently in (1–5, or 0 if below zone 1) |
| `targetZone` | `Int?` | Zone the program requires; `nil` during recovery |
| `phase` | `PhaseType` | Active phase type at this moment |
| `coachingMessage` | `String?` | Coaching message delivered at this moment, if any |

---

## HRReading

Lightweight struct for HR data in transit from Watch to iPhone (not stored permanently).

| Property | Type | Description |
|---|---|---|
| `value` | `Int` | Raw HR reading in bpm |
| `timestamp` | `Date` | Time reading was taken |

---

## CoachingState

Current snapshot of workout state published to the UI every coaching tick.

| Property | Type | Description |
|---|---|---|
| `currentHR` | `Int` | Most recent raw HR reading |
| `hrSmooth` | `Int` | Smoothed HR (average of last 2 readings) |
| `currentZone` | `Int` | Zone user is currently in |
| `targetZone` | `Int?` | Zone required by current phase |
| `phase` | `PhaseType` | Current phase type |
| `phaseTimeRemaining` | `TimeInterval` | Seconds left in current phase |
| `elapsedTime` | `TimeInterval` | Total elapsed workout time |
| `coachingMessage` | `String?` | Active coaching message |
| `isGracePeriodActive` | `Bool` | Whether grace period suppresses coaching |

---

## CoachingCommand (enum)

Command sent from iPhone coaching engine to Apple Watch.

| Case | Description |
|---|---|
| `.haptic(HapticPattern)` | Execute the given haptic pattern |
| `.showCoachingOverlay(String)` | Display zone transition overlay text |
| `.emergencyStop` | Show full-screen emergency stop |
| `.workoutStarted` | Watch activates workout display |
| `.workoutStopped` | Watch deactivates workout display |

---

## HapticPattern (enum)

| Case | Trigger |
|---|---|
| `.short` | HR below target zone ("Speed up") |
| `.long` | HR above target zone ("Slow down") |
| `.doubleTap` | 30s in-zone positive feedback |
| `.emergencyRepeated` | HR above HRmax |

---

## SyncStatus (enum)

| Case | Description |
|---|---|
| `.synced` | Session saved to Firebase successfully |
| `.savedLocally` | Session queued offline |
| `.syncing` | Upload in progress |
| `.failed` | Upload failed after retry |

---

## Supporting Enums

```
Goal:        .fatBurn | .endurance
WorkoutType: .continuous | .hiit | .fartlek
Sex:         .male | .female | .other
```

---

## Entity Relationships

```
UserProfile
  └── goal: Goal
  └── preferredWorkout: WorkoutType

HRZones
  └── zone1..zone5: Zone

WorkoutProgram (enum)
  └── phases: [WorkoutPhase]
        └── type: PhaseType
        └── targetZone: Int?

Session
  └── timeInZones: [Int: Int]
  └── hrStream: [HRRecord]
        └── phase: PhaseType
        └── currentZone: Int
        └── targetZone: Int?

CoachingState (transient — UI only, not stored)
CoachingCommand (transient — Watch communication only)
HRReading (transient — Watch to iPhone in-flight only)
```
