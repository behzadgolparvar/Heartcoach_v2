# Logical Components — Unit 4: Apple Watch App

## Component Map

```
HeartRateCoachCore (Unit 1 SPM — reused, no changes)
  └── HRReading, HapticPattern, CoachingMessage, PhaseType

HeartCoachWatch (watchOS app target)
  └── WatchApp (@main)
      └── WatchSessionManager              ← NEW: WCSession + lifecycle
          ├── HRService                    ← NEW: HKWorkoutSession + HR streaming
          └── HapticService               ← NEW: WKHapticType execution
      └── WorkoutWatchViewModel            ← NEW: @Observable UI state
          ├── WatchRootView                ← NEW: view switcher
          ├── IdleWatchView                ← NEW: waiting screen
          └── WorkoutWatchView             ← NEW: active workout display
```

---

## WatchApp

**Type**: `@main struct` conforming to `App`
**Responsibility**: App entry point. Creates `WatchSessionManager` and `WorkoutWatchViewModel`, injects into environment, triggers session recovery on launch.

```swift
@main
struct WatchApp: App {
    @State private var sessionManager = WatchSessionManager()
    @State private var viewModel = WorkoutWatchViewModel()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(viewModel)
                .onAppear { sessionManager.activate(viewModel: viewModel) }
        }
    }
}
```

---

## WatchSessionManager

**Type**: `final class` + `WCSessionDelegate`
**Responsibility**: Central coordinator. Activates WCSession, routes incoming messages to `HRService` and `HapticService`, triggers session recovery on activation.

| Property | Type | Purpose |
|---|---|---|
| `hrService` | `HRService` | Owned; started/stopped on workout commands |
| `hapticService` | `HapticService` | Owned; fired on haptic commands |
| `viewModel` | `WorkoutWatchViewModel` (weak) | Updated on `@MainActor` after each message |
| `store` | `HKHealthStore` | Passed to `HRService`; used for recovery |

**Key methods**:
```swift
func activate(viewModel: WorkoutWatchViewModel)   // activates WCSession + recovers session
func startWorkout()                               // creates HRService, starts HKWorkoutSession
func stopWorkout()                                // ends HKWorkoutSession, saves to Health
```

**WCSession activation**:
```swift
func activate(viewModel: WorkoutWatchViewModel) {
    self.viewModel = viewModel
    WCSession.default.delegate = self
    WCSession.default.activate()
    recoverIfNeeded()
}
```

---

## HRService

**Type**: `final class` + `HKWorkoutSessionDelegate` + `HKLiveWorkoutBuilderDelegate`
**Responsibility**: Owns `HKWorkoutSession` and `HKLiveWorkoutBuilder`. Streams live HR readings via callback. Handles session recovery.

| Property | Type | Purpose |
|---|---|---|
| `session` | `HKWorkoutSession?` | Active session; nil when idle |
| `builder` | `HKLiveWorkoutBuilder?` | Collects live samples |
| `store` | `HKHealthStore` | Required for session creation and recovery |
| `onHRReading` | `((HRReading) -> Void)?` | Called by `WatchSessionManager` to send HR to iPhone |

**Normal flow**: `start()` → session active → builder delivers HR samples → `onHRReading` fires → `WatchSessionManager.sendHR()` → WCSession

**Recovery flow**: `reconnect(to:)` → re-attach delegates to recovered session → builder re-delivers samples on next sensor reading

**Session end**: `stop()` → `session.end()` → `builder.finishWorkout()` saves to Apple Health

---

## HapticService

**Type**: `final class`
**Responsibility**: Translates `HapticPattern` to `WKHapticType` and fires the Taptic Engine. Thread-safe — callable from any queue.

```swift
final class HapticService {
    func play(_ pattern: HapticPattern) {
        let type: WKHapticType = {
            switch pattern {
            case .short:             return .notification
            case .long:              return .directionUp
            case .doubleTap:         return .success
            case .emergencyRepeated: return .retry
            }
        }()
        WKInterfaceDevice.current().play(type)
    }
}
```

No state, no dependencies beyond WatchKit. Pure function in practice.

---

## WorkoutWatchViewModel

**Type**: `@Observable final class`
**Responsibility**: Observable state for Watch SwiftUI views. All properties mutated on `@MainActor`.

| Property | Type | Default | Source |
|---|---|---|---|
| `isWorkoutActive` | `Bool` | `false` | Set by `WatchSessionManager` on start/stop commands |
| `currentHR` | `Int` | `0` | Updated on each HR reading from `HRService` |
| `currentZone` | `Int` | `0` | Decoded from iPhone's coaching state message |
| `phaseName` | `String` | `""` | Decoded from iPhone's coaching state message |
| `lastMessage` | `String?` | `nil` | Decoded from iPhone's coaching state message |

**Update pattern** (from `WatchSessionManager`):
```swift
Task { @MainActor in
    viewModel.currentHR = reading.value
}
```

---

## WatchRootView

**Type**: SwiftUI `View`
**Responsibility**: Switches between `IdleWatchView` and `WorkoutWatchView` based on `viewModel.isWorkoutActive`.

```swift
struct WatchRootView: View {
    @Environment(WorkoutWatchViewModel.self) private var vm
    var body: some View {
        if vm.isWorkoutActive {
            WorkoutWatchView()
        } else {
            IdleWatchView()
        }
    }
}
```

---

## IdleWatchView

**Type**: SwiftUI `View`
**Shown when**: `isWorkoutActive == false`
**Content**: HeartCoach heart icon + app name + "Start workout on iPhone" instruction. No interactive elements.

---

## WorkoutWatchView

**Type**: SwiftUI `View`
**Shown when**: `isWorkoutActive == true`
**Content**: Phase name (top), HR number (large, zone-colored), zone label, last coaching message (bottom). No interactive elements — all workout control is on iPhone.

Zone colors: zone 1 = blue, 2 = green, 3 = yellow, 4 = orange, 5 = red. HR number color matches zone.

---

## Component Interaction Diagram

```
iPhone WatchBridge
  │  ["command": "workoutStarted"]
  │  ["haptic": "short"]
  │  ["zone": 3, "phase": "exercise", "message": "Speed up"]
  ▼
WatchSessionManager.session(_:didReceiveMessage:)
  ├── command → HRService.start() / stop()
  ├── haptic  → HapticService.play(_:)          → Taptic Engine
  └── state   → WorkoutWatchViewModel (@MainActor)
                    └── WorkoutWatchView re-renders

HRService (HKLiveWorkoutBuilder delegate)
  ├── onHRReading → WatchSessionManager.sendHR()
  │       └── WCSession.sendMessage(["hr": bpm])  → iPhone WatchBridge
  └── onHRReading → WorkoutWatchViewModel.currentHR (@MainActor)
```

---

## Unit → Target Mapping

| Component | Target |
|---|---|
| `WatchApp` | `HeartCoachWatch` |
| `WatchSessionManager` | `HeartCoachWatch` |
| `HRService` | `HeartCoachWatch` |
| `HapticService` | `HeartCoachWatch` |
| `WorkoutWatchViewModel` | `HeartCoachWatch` |
| `WatchRootView`, `IdleWatchView`, `WorkoutWatchView` | `HeartCoachWatch` |
| `HRReading`, `HapticPattern`, `PhaseType` | `HeartRateCoachCore` (reused, no changes) |
