# Unit 4 — Apple Watch App: Code Summary

## Architecture

```
WatchApp (@main)
  └─ WatchSessionManager (WCSessionDelegate)
       ├─ HRService (HKWorkoutSessionDelegate + HKLiveWorkoutBuilderDelegate)
       ├─ HapticService
       └─ WorkoutWatchViewModel (@Observable, @MainActor)
            └─ WatchRootView → IdleWatchView | WorkoutWatchView
```

## Key Decisions

### Session Recovery (NFR Design Q1 = A)
- `WatchSessionManager.recoverIfNeeded()` calls `HKHealthStore().recoverActiveWorkoutSession` on WCSession activation
- Reconnects `HRService` delegates to the recovered session without discarding data
- Triggers `viewModel.isWorkoutActive = true` so UI reflects active workout after suspension recovery

### Workout Save (NFR Requirements Q1 = A)
- `HRService.stop()` calls `builder.finishWorkout()` — saves workout to Apple Health
- Never calls `discardWorkout()` so all HR data is retained

### Watch Idle State (Functional Design Q3 = A)
- Watch is iPhone-controlled only: workout starts/stops via `["command": "workoutStarted/Stopped"]` WCSession messages
- `IdleWatchView` shows "Start workout on iPhone" — no interactive elements
- Watch-initiated start is explicitly out of scope (noted as future enhancement)

### Haptic Mapping (Functional Design Q4 = A)
- `.short` → `WKHapticType.directedUp` (HR below zone — go up/faster)
- `.long` → `WKHapticType.directedDown` (HR above zone — slow down)
- `.doubleTap` → `WKHapticType.success` (30s in-zone positive feedback)
- `.emergencyRepeated` → `WKHapticType.notification` (emergency stop)

### WCSession Message Contracts (Watch ← iPhone)
| Key | Type | Meaning |
|---|---|---|
| `"command"` | String | `"workoutStarted"` or `"workoutStopped"` |
| `"haptic"` | String | `HapticPattern.rawValue` |
| `"zone"` | Int | Current HR zone (1–5, 0 = no signal) |
| `"phase"` | String | `PhaseType.rawValue` |
| `"message"` | String? | Active coaching message text (optional) |

### WCSession Message Contract (Watch → iPhone)
| Key | Type | Meaning |
|---|---|---|
| `"hr"` | Int | HR reading in bpm |

### HKWorkoutConfiguration
- `activityType = .other` — app supports any HR-based activity, not running-specific
- `locationType = .unknown` — no GPS required

## Files Created / Modified

| File | Action | Notes |
|---|---|---|
| `HeartCoachWatch/WatchApp.swift` | NEW | `@main` entry; creates SessionManager + ViewModel |
| `HeartCoachWatch/HapticService.swift` | NEW | Stateless; maps HapticPattern → WKHapticType |
| `HeartCoachWatch/HRService.swift` | NEW | HKWorkoutSession + HKLiveWorkoutBuilder |
| `HeartCoachWatch/WatchSessionManager.swift` | NEW | WCSessionDelegate; routes commands, haptics, state |
| `HeartCoachWatch/WorkoutWatchViewModel.swift` | NEW | `@Observable @MainActor`; 5 UI properties |
| `HeartCoachWatch/Views/WatchRootView.swift` | NEW | Switches Idle ↔ Workout on `isWorkoutActive` |
| `HeartCoachWatch/Views/IdleWatchView.swift` | NEW | Static "Start on iPhone" prompt |
| `HeartCoachWatch/Views/WorkoutWatchView.swift` | NEW | HR, zone color, phase, coaching message |
| `HeartCoach/Workout/WatchBridge.swift` | MODIFIED | Added `sendCoachingState(_:)`, `sendCommand(_:)` |
| `HeartCoach/Workout/WorkoutSessionManager.swift` | MODIFIED | Sends `workoutStarted/Stopped` commands + coaching state |
| `HeartCoachWatchTests/HapticServiceTests.swift` | NEW | RawValue decode tests; HapticService smoke test |

## Security Constraints Applied
- SECURITY-03: HR values pass through `HRService.onHRReading` callback only — never logged
- HealthKit authorization requested at session start; graceful no-op if denied
- No HR or health data written to persistent storage on Watch side
