# Code Summary — Unit 3: iPhone Workout Engine

## Key Implementation Notes

### CoachingEngine in HeartRateCoachCore (not HeartCoach)
`CoachingEngine` and `CoachingEngineState` are in the shared SPM package (`HeartRateCoachCore`) rather than the iPhone app target. This is intentional: Unit 4 (Apple Watch app) will reuse the same coaching logic without duplication.

### Stale HR sentinel: Int.max
`WorkoutSessionManager` passes `Int.max` as the `hr` parameter when the HR signal is stale (≥15 seconds since last reading). `CoachingEngine.tick()` detects `Int.max` and short-circuits to Layer 1 "no signal" before touching the HR buffer. This keeps staleness logic outside `CoachingEngineState` — the engine stays pure.

### `now: Date` injection for determinism
`CoachingEngine.tick()` accepts a `now: Date = Date()` parameter. Tests pass a fixed `Date` to eliminate time-dependent non-determinism from PBT runs. Production callers use the default.

### WorkoutSessionManager is @MainActor
`WorkoutSessionManager` is annotated `@MainActor` to ensure all state mutations happen on the main thread. The `Task` tick loop calls `await MainActor.run { processTick() }` from a background cooperative thread.

### Per-session WorkoutViewModel lifecycle
`AppContainer.makeWorkoutViewModel(zones:)` creates a fresh `WorkoutViewModel` (and thus a fresh `WorkoutSessionManager`) for each workout. This avoids stale state between sessions. `HomeView` holds the `WorkoutViewModel` in a `@State` property for the duration of the workout flow.

### HapticPattern.rawValue for WCSession serialization
`HapticPattern` is a Swift enum without explicit raw values. `WatchBridge` sends `pattern.rawValue` as the WCSession message dictionary value. The Watch app (Unit 4) will decode this string to fire the appropriate haptic on the Watch side.

### HistoryPlaceholderView replaced
`HeartCoach/Views/History/HistoryPlaceholderView.swift` (from Unit 2) is superseded by `HistoryView.swift`. The placeholder file should be deleted before running XcodeGen to avoid duplicate type declaration errors.

## Files Added

### HeartRateCoachCore (SPM package)
- `Sources/HeartRateCoachCore/Models/CoachingMessage.swift`
- `Sources/HeartRateCoachCore/Engine/CoachingEngineState.swift`
- `Sources/HeartRateCoachCore/Engine/CoachingEngine.swift`
- `Tests/HeartRateCoachCoreTests/Helpers/Generators.swift` (updated — added CoachingEngineState + WorkoutPhase generators)
- `Tests/HeartRateCoachCoreTests/CoachingEngineTests.swift`

### HeartCoach (iPhone app target)
- `Workout/VoiceFeedbackService.swift`
- `Workout/WatchBridge.swift`
- `Workout/WorkoutSessionManager.swift`
- `ViewModels/WorkoutViewModel.swift`
- `ViewModels/WorkoutSummaryViewModel.swift`
- `ViewModels/HistoryViewModel.swift`
- `Views/Workout/WorkoutPreStartView.swift`
- `Views/Workout/ZoneRingView.swift`
- `Views/Workout/WorkoutView.swift`
- `Views/Workout/EmergencyStopOverlay.swift`
- `Views/Summary/WorkoutSummaryView.swift`
- `Views/History/HistoryView.swift`
- `Views/History/SessionDetailView.swift`

### Updated
- `App/AppContainer.swift` — VoiceFeedbackService, WatchBridge, WorkoutSummaryViewModel, HistoryViewModel added; makeWorkoutViewModel() factory added
- `App/HeartCoachApp.swift` — summaryViewModel and historyViewModel injected into environment
- `Views/Home/HomeView.swift` — Start Workout button now creates WorkoutViewModel and navigates to WorkoutPreStartView
- `project.yml` — WatchConnectivity.framework added to HeartCoach target dependencies

### HeartCoachTests
- `Mocks/MockVoiceFeedbackService.swift`
- `Mocks/MockWatchBridge.swift`
- `WorkoutViewModelTests.swift`

## Action Before XcodeGen
Delete the now-superseded placeholder:
```bash
rm HeartCoach/Views/History/HistoryPlaceholderView.swift
```
Then run:
```bash
xcodegen generate
```
