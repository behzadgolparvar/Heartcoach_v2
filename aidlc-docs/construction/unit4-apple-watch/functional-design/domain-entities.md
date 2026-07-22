# Domain Entities — Unit 4: Apple Watch App

## Component Overview

The Watch app has four responsibilities: sense HR, stream HR to iPhone, execute haptics, and display workout status. Each is handled by a dedicated component.

```
WatchApp (@main)
  └── WatchSessionManager       ← WCSession + lifecycle coordinator
      ├── HRService              ← HKWorkoutSession + HR streaming
      └── HapticService          ← WKHapticType execution
  └── WorkoutWatchViewModel      ← @Observable UI state
      ├── WorkoutWatchView       ← active workout screen
      └── IdleWatchView          ← waiting screen (no active workout)
```

---

## WatchSessionManager

**Type**: `final class` + `WCSessionDelegate`
**Responsibility**: Central coordinator. Activates WCSession, bridges iPhone commands to Watch services, and sends HR readings back to iPhone.

| Property | Type | Purpose |
|---|---|---|
| `hrService` | `HRService` | Owned HR sensor service |
| `hapticService` | `HapticService` | Owned haptic service |
| `onStateUpdate` | `((WatchWorkoutState) -> Void)?` | Callback to ViewModel on each HR reading or command received |

**WCSession message handling**:

| Message key | Value | Action |
|---|---|---|
| `"command"` | `"workoutStarted"` | Start `HRService`; update state to active |
| `"command"` | `"workoutStopped"` | Stop `HRService`; update state to idle |
| `"haptic"` | `HapticPattern.rawValue` | Decode and pass to `HapticService` |

**HR send** (called by `HRService` on each new reading):
```swift
func sendHR(_ reading: HRReading) {
    guard WCSession.default.isReachable else { return }
    WCSession.default.sendMessage(["hr": reading.value], replyHandler: nil, errorHandler: { _ in })
}
```

---

## HRService

**Type**: `final class`
**Responsibility**: Owns and manages `HKWorkoutSession` + `HKLiveWorkoutBuilder`. Streams live HR readings to `WatchSessionManager` via callback.

| Property | Type | Purpose |
|---|---|---|
| `session` | `HKWorkoutSession?` | Active workout session (nil when idle) |
| `builder` | `HKLiveWorkoutBuilder?` | Collects live quantity samples |
| `onHRReading` | `((HRReading) -> Void)?` | Fired on each new HR sample (~every 5s) |

**Lifecycle**:
- `start()` — creates `HKWorkoutConfiguration` (activity: `.running`), requests `HKWorkoutSession`, calls `session.startActivity(with:)` and `builder.beginCollection(withStart:)`
- `stop()` — calls `session.end()`, `builder.endCollection(withEnd:)`, discards builder data (session history not needed on Watch)

**HR delivery**: `HKLiveWorkoutBuilderDelegate.workoutBuilder(_:didCollectDataOf:)` fires when new HR samples arrive. Extracts the most recent `HKQuantitySample` for `HKQuantityTypeIdentifier.heartRate`, converts to `Int` bpm, wraps in `HRReading`, calls `onHRReading`.

---

## HapticService

**Type**: `final class`
**Responsibility**: Maps `HapticPattern` → `WKHapticType` and fires the Watch Taptic Engine.

| `HapticPattern` | `WKHapticType` | Sensation |
|---|---|---|
| `.short` | `.notification` | Single short tap — gentle nudge (HR too low) |
| `.long` | `.directionUp` | Two quick upward taps — more urgent (HR too high) |
| `.doubleTap` | `.success` | Satisfying double tap — positive reward (30s in-zone) |
| `.emergencyRepeated` | `.retry` | Repeated tapping — most insistent (emergency stop) |

```swift
func play(_ pattern: HapticPattern) {
    let type: WKHapticType
    switch pattern {
    case .short:             type = .notification
    case .long:              type = .directionUp
    case .doubleTap:         type = .success
    case .emergencyRepeated: type = .retry
    }
    WKInterfaceDevice.current().play(type)
}
```

---

## WatchWorkoutState

**Type**: `struct` (value type — snapshot passed to ViewModel)
**Responsibility**: Lightweight state snapshot produced by `WatchSessionManager` after each HR reading or command.

| Property | Type | Purpose |
|---|---|---|
| `isWorkoutActive` | `Bool` | True when a workout is running |
| `currentHR` | `Int` | Most recent HR reading in bpm; 0 if no reading yet |
| `lastMessage` | `String?` | Last coaching message text received from iPhone; nil if none |

`currentZone` and `phaseName` are received from iPhone via additional WCSession message fields (see business-logic-model.md).

---

## WorkoutWatchViewModel

**Type**: `@Observable final class`
**Responsibility**: Observable state for the Watch SwiftUI views. Updated on main thread by `WatchSessionManager`.

| Property | Type | Purpose |
|---|---|---|
| `isWorkoutActive` | `Bool` | Switches between `IdleWatchView` and `WorkoutWatchView` |
| `currentHR` | `Int` | HR displayed in large on `WorkoutWatchView` |
| `currentZone` | `Int` | Zone number (1–5) for color coding; 0 if no zone |
| `phaseName` | `String` | "Warm Up" / "Exercise" / "Recovery" / "Cool Down" |
| `lastMessage` | `String?` | Coaching message text shown at bottom of screen |

---

## Future Enhancement Note

**Watch-initiated workout start** (decided out of scope for Unit 4, 2026-07-22):

Currently the Watch waits for a `workoutStarted` command from the iPhone. A future version could add a program picker and Start button on `IdleWatchView`, sending a `workoutStarted` command Watch → iPhone. The architecture supports this:
- `WatchSessionManager` would need to send rather than receive the start command
- `WatchBridge` on the iPhone would need a `session(_:didReceiveMessage:)` handler for start/stop commands
- No changes needed to `CoachingEngine`, `WorkoutSessionManager`, or any coaching logic
