# Code Generation Plan — Unit 4: Apple Watch App

## Unit Context

- **Unit**: Apple Watch App
- **Location**: `HeartCoachWatch/` at workspace root
- **Language**: Swift 5.9, SwiftUI, watchOS 10+
- **Dependencies**: HeartRateCoachCore (Unit 1)
- **Stories covered**: US-17, US-18
- **Depends on**: Unit 1 (HeartRateCoachCore), Unit 3 (iPhone Workout Engine — WatchBridge)

## Design Sources
- `aidlc-docs/construction/unit4-apple-watch/functional-design/`
- `aidlc-docs/construction/unit4-apple-watch/nfr-requirements/`
- `aidlc-docs/construction/unit4-apple-watch/nfr-design/`

---

## New Files

```
HeartCoachWatch/
  WatchApp.swift
  WatchSessionManager.swift
  HRService.swift
  HapticService.swift
  WorkoutWatchViewModel.swift
  Views/
    WatchRootView.swift
    IdleWatchView.swift
    WorkoutWatchView.swift
  HeartCoachWatch.entitlements
```

## Modified Files

```
project.yml                              ← add HeartCoachWatch watchOS target
HeartCoach/Workout/WatchBridge.swift     ← add sendCoachingState(_:) method
HeartCoach/Workout/WorkoutSessionManager.swift  ← call sendCoachingState in processTick()
aidlc-docs/construction/unit4-apple-watch/code/code-summary.md  ← NEW doc
```

---

## Generation Checklist

### Phase 1: Project Setup

- [x] **Step 1** — Update `project.yml`
  - Add `HeartCoachWatch` watchOS app target (watchOS 10+)
  - Bundle ID: `com.behzad.heartcoach.watchkitapp`
  - Dependencies: `HeartRateCoachCore` SPM, `WatchConnectivity.framework`
  - Entitlements path: `HeartCoachWatch/HeartCoachWatch.entitlements`
  - Companion app bundle: `com.behzad.heartcoach`

- [x] **Step 2** — Create `HeartCoachWatch/` directory structure

- [x] **Step 3** — Create `HeartCoachWatch/HeartCoachWatch.entitlements`
  - `com.apple.developer.healthkit` = true
  - `com.apple.developer.healthkit.background-delivery` = true

---

### Phase 2: Watch App Core

- [x] **Step 4** — Create `HeartCoachWatch/WatchApp.swift`
  - `@main struct WatchApp: App`
  - Creates `WatchSessionManager` + `WorkoutWatchViewModel`
  - Calls `sessionManager.activate(viewModel:)` in `.onAppear`
  - Injects `viewModel` into SwiftUI environment

- [x] **Step 5** — Create `HeartCoachWatch/HapticService.swift`
  - `final class HapticService`
  - `func play(_ pattern: HapticPattern)` — maps to `WKHapticType` and fires `WKInterfaceDevice.current().play(_:)`
  - Thread-safe (no state)

- [x] **Step 6** — Create `HeartCoachWatch/HRService.swift`
  - `final class HRService: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate`
  - `func start()` — creates `HKWorkoutConfiguration`, `HKWorkoutSession`, `HKLiveWorkoutBuilder`, begins collection
  - `func stop()` — ends session, calls `builder.finishWorkout()` (saves to Apple Health)
  - `func reconnect(to session: HKWorkoutSession)` — re-attaches delegates for recovery
  - `var onHRReading: ((HRReading) -> Void)?` — callback on each new HR sample
  - `workoutBuilder(_:didCollectDataOf:)` — extracts HR quantity, converts to bpm, calls `onHRReading`

- [x] **Step 7** — Create `HeartCoachWatch/WatchSessionManager.swift`
  - `final class WatchSessionManager: WCSessionDelegate`
  - `func activate(viewModel: WorkoutWatchViewModel)` — activates WCSession, calls `recoverIfNeeded()`
  - `func sendHR(_ reading: HRReading)` — fire-and-forget `sendMessage(["hr": bpm])`
  - `session(_:didReceiveMessage:)` — routes: command → start/stop HRService; haptic → HapticService; state → ViewModel
  - `recoverIfNeeded()` — `HKHealthStore().recoverActiveWorkoutSession` on activation

- [x] **Step 8** — Create `HeartCoachWatch/WorkoutWatchViewModel.swift`
  - `@Observable final class WorkoutWatchViewModel`
  - Properties: `isWorkoutActive`, `currentHR`, `currentZone`, `phaseName`, `lastMessage`
  - All updates on `@MainActor`

---

### Phase 3: Watch Views

- [x] **Step 9** — Create `HeartCoachWatch/Views/WatchRootView.swift`
  - Switches between `IdleWatchView` and `WorkoutWatchView` on `viewModel.isWorkoutActive`
  - `@Environment(WorkoutWatchViewModel.self)` binding

- [x] **Step 10** — Create `HeartCoachWatch/Views/IdleWatchView.swift`
  - Heart icon + "HeartCoach" + "Start workout on iPhone"
  - No interactive elements

- [x] **Step 11** — Create `HeartCoachWatch/Views/WorkoutWatchView.swift`
  - Phase name (top, `.caption`)
  - HR number (large, zone-colored) + "BPM" label
  - Zone label ("Zone N", zone-colored)
  - Last coaching message (bottom, `.footnote`, optional)
  - Zone color map: 1=blue, 2=green, 3=yellow, 4=orange, 5=red, 0=gray

---

### Phase 4: iPhone WatchBridge Update

- [x] **Step 12** — Update `HeartCoach/Workout/WatchBridge.swift`
  - Add `func sendCoachingState(_ state: CoachingState)` — sends `["zone": N, "phase": rawValue, "message": text]` fire-and-forget
  - Add to `WatchBridgeProtocol`

- [x] **Step 13** — Update `HeartCoach/Workout/WorkoutSessionManager.swift`
  - In `processTick()`, after publishing `CoachingState` to ViewModel, also call `watchBridge.sendCoachingState(coachingState)`
  - Also send `["command": "workoutStarted"]` / `["command": "workoutStopped"]` in `start()` / `end()`

---

### Phase 5: Tests

- [x] **Step 14** — Create `HeartCoachWatchTests/HapticServiceTests.swift`
  - Verifies all 4 `HapticPattern` cases map without crashing (integration smoke test)
  - Verifies `HapticPattern(rawValue:)` decoding for all WCSession-received raw values

---

### Phase 6: Documentation

- [x] **Step 15** — Create `aidlc-docs/construction/unit4-apple-watch/code/code-summary.md`

---

**Total: 15 steps across 6 phases**

Please review and approve this plan, or request changes before code generation begins.
