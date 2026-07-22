# Code Generation Plan — Unit 3: iPhone Workout Engine

## Unit Context

- **Unit**: iPhone Workout Engine
- **Location**: `HeartRateCoachCore/` (SPM extension) + `HeartCoach/` (app target)
- **Language**: Swift 5.9, SwiftUI, iOS 17+
- **Dependencies**: HeartRateCoachCore (Unit 1), HeartCoach app (Unit 2)
- **Stories covered**: US-06, US-07, US-08, US-09, US-10, US-11, US-12, US-13, US-14, US-15, US-16
- **Depends on**: Unit 1 (HeartRateCoachCore), Unit 2 (iPhone Foundation)

## Design Sources
- `aidlc-docs/construction/unit3-workout-engine/functional-design/`
- `aidlc-docs/construction/unit3-workout-engine/nfr-requirements/`
- `aidlc-docs/construction/unit3-workout-engine/nfr-design/`

---

## New Files

```
HeartRateCoachCore/Sources/HeartRateCoachCore/
  Engine/
    CoachingEngineState.swift          ← NEW
    CoachingEngine.swift               ← NEW
  Models/
    CoachingMessage.swift              ← NEW (text + optional HapticPattern)

HeartCoach/
  Workout/
    WorkoutSessionManager.swift        ← NEW
    VoiceFeedbackService.swift         ← NEW
    WatchBridge.swift                  ← NEW
  ViewModels/
    WorkoutViewModel.swift             ← NEW
    WorkoutSummaryViewModel.swift      ← NEW
    HistoryViewModel.swift             ← NEW
  Views/
    Workout/
      WorkoutPreStartView.swift        ← NEW
      WorkoutView.swift                ← NEW
      ZoneRingView.swift               ← NEW (component)
      EmergencyStopOverlay.swift       ← NEW
    Summary/
      WorkoutSummaryView.swift         ← NEW
    History/
      HistoryView.swift                ← NEW (replaces placeholder)
      SessionDetailView.swift          ← NEW

HeartRateCoachCoreTests/
  Helpers/
    Generators.swift                   ← UPDATE (add CoachingEngineState + WorkoutPhase gens)
  CoachingEngineTests.swift            ← NEW

HeartCoachTests/
  Mocks/
    MockVoiceFeedbackService.swift     ← NEW
    MockWatchBridge.swift              ← NEW
  WorkoutViewModelTests.swift          ← NEW
```

## Modified Files

```
HeartCoach/App/AppContainer.swift      ← wire WorkoutSessionManager factory
HeartCoach/Views/Home/HomeView.swift   ← enable Start Workout → WorkoutPreStartView
project.yml                            ← add WatchConnectivity framework
aidlc-docs/construction/unit3-workout-engine/code/code-summary.md  ← NEW doc
```

---

## Generation Checklist

### Phase 1: HeartRateCoachCore Extensions

- [x] **Step 1** — Create `HeartRateCoachCore/Sources/HeartRateCoachCore/Models/CoachingMessage.swift`
  - `struct CoachingMessage` with `text: String`, `hapticPattern: HapticPattern?`, `layer: Int`
  - Layer constants: 1 = Safety, 2 = Zone Coaching, 3 = Positive Feedback
  - Predefined static factory methods for each coaching scenario

- [x] **Step 2** — Create `HeartRateCoachCore/Sources/HeartRateCoachCore/Engine/CoachingEngineState.swift`
  - `struct CoachingEngineState` (value type)
  - `hrBuffer: [Int]` — last 2 readings
  - `lastLayer2MessageAt: Date?` — anti-spam timestamp
  - `consecutiveInZoneSeconds: TimeInterval` — Layer 3 counter
  - `var hrSmooth: Int` — computed ceiling average from buffer
  - `mutating func resetForPause()` — zeros streak, clears anti-spam

- [x] **Step 3** — Create `HeartRateCoachCore/Sources/HeartRateCoachCore/Engine/CoachingEngine.swift`
  - `enum CoachingEngine` (namespace — cannot be instantiated)
  - `static func tick(hr:phase:elapsedInPhase:state:zones:now:) -> CoachingMessage?`
  - Private helpers: `updateBuffer`, `evaluateLayer1`, `evaluateLayer2`, `evaluateLayer3`
  - Layer 1: fires if `hrSmooth > zones.zone5.max` (emergency stop) or within 5% of zone5.max
  - Layer 2: skipped if `phase.targetZone == nil`, grace < 10s, or anti-spam < 20s
  - Layer 3: fires if `consecutiveInZoneSeconds >= 30` and user is in target zone
  - Mutual exclusion: early return after each layer

---

### Phase 2: Core Services

- [x] **Step 4** — Create `HeartCoach/Workout/VoiceFeedbackService.swift`
  - `protocol VoiceFeedbackServiceProtocol`: `isMuted`, `speak(_:)`, `stopSpeaking()`, `configureAudioSession()`
  - `final class VoiceFeedbackService: VoiceFeedbackServiceProtocol`
  - `AVAudioSession` configured with `.playback`, `.duckOthers`, `.allowBluetooth`
  - `AVSpeechSynthesisVoice(language: "en-US")` always
  - `stopSpeaking(at: .immediate)` before every utterance
  - Layer 1 messages bypass `isMuted` check

- [x] **Step 5** — Create `HeartCoach/Workout/WatchBridge.swift`
  - `protocol WatchBridgeProtocol`: `onHRReceived: ((HRReading) -> Void)?`, `sendHaptic(_:)`, `activate()`, `deactivate()`
  - `final class WatchBridge: NSObject, WatchBridgeProtocol, WCSessionDelegate`
  - `session(_:didReceiveMessage:)` — dispatch HR to main actor via `onHRReceived` closure
  - `sendHaptic(_:)` — `WCSession.default.sendMessage` fire-and-forget, silent error handler
  - `activate()` / `deactivate()` — `WCSession.default.activate()` / no-op teardown

- [x] **Step 6** — Create `HeartCoach/Workout/WorkoutSessionManager.swift`
  - `final class WorkoutSessionManager`
  - Stored properties: `engineState: CoachingEngineState`, `sequencer: WorkoutPhaseSequencer`, `lastHRReceived: HRReading?`, `tickTask: Task<Void, Never>?`, `hrRecords: [HRRecord]`, `sessionStartDate: Date?`
  - `func start(program:profile:zones:)` — configures audio session, activates WatchBridge, starts tick loop
  - `func pause()` — cancels tick task, resets engine state for pause
  - `func resume()` — recreates tick task
  - `func end() async -> Session` — stops tick loop, builds Session from hrRecords
  - `func emergencyStop()` — immediate end
  - `private func processTick()` — staleness check → CoachingEngine.tick() → voice → haptic → advance sequencer → publish CoachingState to ViewModel
  - `var onStateUpdate: ((CoachingState) -> Void)?` — callback to WorkoutViewModel (MainActor)
  - HR staleness: <15s = use last known; ≥15s = Layer 1 "no signal"

---

### Phase 3: ViewModels

- [x] **Step 7** — Create `HeartCoach/ViewModels/WorkoutViewModel.swift`
  - `@Observable final class WorkoutViewModel`
  - `coachingState: CoachingState`, `activePhase: WorkoutPhase?`, `elapsedTime: TimeInterval`, `isPaused: Bool`, `lastMessage: CoachingMessage?`, `isWorkoutActive: Bool`
  - Actions: `start(program:)`, `pause()`, `resume()`, `end()`, `emergencyStop()`
  - Creates `WorkoutSessionManager` (injected services from AppContainer)
  - Publishes `Session` on workout end for handoff to `WorkoutSummaryViewModel`

- [x] **Step 8** — Create `HeartCoach/ViewModels/WorkoutSummaryViewModel.swift`
  - `@Observable final class WorkoutSummaryViewModel`
  - `session: Session`, `avgHR: Int`, `peakHR: Int`, `timePerZone: [Int: TimeInterval]`, `saveState: SaveState`
  - `enum SaveState: .idle, .saving, .saved, .failed(AppError)`
  - `func saveSession(userID: String)` — calls `FirestoreService.saveSession`
  - `avgHR` and `timePerZone` computed from `session.hrRecords` on init

- [x] **Step 9** — Create `HeartCoach/ViewModels/HistoryViewModel.swift`
  - `@Observable final class HistoryViewModel`
  - `sessions: [Session]`, `isLoading: Bool`, `error: AppError?`, `hasMore: Bool`
  - `func loadInitial(userID:)` — loads first 10 sessions
  - `func loadMore(userID:)` — increments limit by 10

---

### Phase 4: Workout Views

- [x] **Step 10** — Create `HeartCoach/Views/Workout/WorkoutPreStartView.swift`
  - Program selection: Continuous, HIIT, Fartlek (3 cards)
  - Each card shows program name + phase count + estimated duration
  - "Start" button navigates to `WorkoutView`, calling `workoutVM.start(program:)`
  - Back button returns to Home

- [x] **Step 11** — Create `HeartCoach/Views/Workout/ZoneRingView.swift`
  - Circular ring showing current zone (1–5) in zone color
  - HR value in center, zone label below
  - Animates on zone change
  - Accessibility: `accessibilityLabel("Zone \(zone), \(hr) BPM")`

- [x] **Step 12** — Create `HeartCoach/Views/Workout/WorkoutView.swift`
  - Three display states driven by `workoutVM`:
    - **Active**: `ZoneRingView` + phase name + elapsed time + last coaching message
    - **Recovery**: Recovery phase indicator + countdown to next phase
    - **Paused**: "Paused" banner + Resume + End buttons
  - Top-right: Emergency Stop button (always visible) → `EmergencyStopOverlay`
  - Bottom: Pause / Resume toggle button
  - Listens to `workoutVM.isWorkoutActive` — navigates to `WorkoutSummaryView` when false

- [x] **Step 13** — Create `HeartCoach/Views/Workout/EmergencyStopOverlay.swift`
  - Full-screen overlay with warning color
  - Message: "Emergency Stop — Are you sure?"
  - Confirm button: calls `workoutVM.emergencyStop()`
  - Cancel button: dismisses overlay

---

### Phase 5: Summary & History Views

- [x] **Step 14** — Create `HeartCoach/Views/Summary/WorkoutSummaryView.swift`
  - Header: program name + date + total duration
  - Stats row: avg HR, peak HR
  - Zone time breakdown: 5 rows with zone label + colored bar + duration
  - "Save" button → `summaryVM.saveSession(userID:)`; disabled after saved
  - "Done" button → pops to Home

- [x] **Step 15** — Replace `HeartCoach/Views/History/HistoryPlaceholderView.swift` with `HistoryView.swift`
  - `List` of sessions: date + program name + duration + avg HR
  - On tap → `SessionDetailView`
  - `onAppear` → `historyVM.loadInitial(userID:)`
  - "Load More" button at bottom when `historyVM.hasMore`
  - Empty state when no sessions

- [x] **Step 16** — Create `HeartCoach/Views/History/SessionDetailView.swift`
  - Full detail of one past session
  - Same layout as `WorkoutSummaryView` but read-only (no Save button)

---

### Phase 6: App Wiring

- [x] **Step 17** — Update `project.yml`
  - Add `WatchConnectivity.framework` to `HeartCoach` target link libraries
  - Existing capabilities (HealthKit, Sign in with Apple) unchanged

- [x] **Step 18** — Update `HeartCoach/App/AppContainer.swift`
  - Add `VoiceFeedbackService`, `WatchBridge` instances
  - Add factory method `makeWorkoutSessionManager() -> WorkoutSessionManager` (creates per-session)
  - Add `WorkoutSummaryViewModel`, `HistoryViewModel` instances
  - Inject `HistoryViewModel` and `WorkoutSummaryViewModel` into environment in `HeartCoachApp.swift`

- [x] **Step 19** — Update `HeartCoach/Views/Home/HomeView.swift`
  - Enable "Start Workout" button → navigates to `WorkoutPreStartView`
  - Previously disabled when HealthKit denied (logic unchanged — keep that guard)
  - Add `NavigationLink` to `WorkoutPreStartView`

---

### Phase 7: Tests — HeartRateCoachCore

- [x] **Step 20** — Update `HeartRateCoachCoreTests/Helpers/Generators.swift`
  - Add `Gen<CoachingEngineState>` — generates states with random buffer, random anti-spam timestamp (nil or past 0–60s ago), random in-zone counter (0–60)
  - Add `Gen<WorkoutPhase>` — generates phases with/without target zone, with/without grace period active

- [x] **Step 21** — Create `HeartRateCoachCoreTests/CoachingEngineTests.swift`
  - **Example-based tests** (at least 8):
    - Layer 1 fires when HR > zone5.max
    - Layer 1 fires when HR is near-max
    - Layer 2 fires at correct zone coaching message
    - Layer 2 suppressed during grace period (elapsedInPhase < 10s)
    - Layer 2 suppressed by anti-spam (< 20s since last)
    - Layer 3 fires at consecutiveInZoneSeconds == 30
    - Layer 3 does not fire at consecutiveInZoneSeconds == 25
    - Layer 1 + Layer 2 mutual exclusion (Layer 1 wins)
  - **PBT tests** (9 invariants from nfr-requirements.md via SwiftCheck):
    - Layer 1 always fires when HR > zone5.max regardless of state
    - Layer 2 never fires when phase.targetZone == nil
    - Layer 2 never fires when elapsedInPhase < 10.0
    - Layer 2 never fires within 20s of lastLayer2MessageAt
    - Layer 3 never fires when consecutiveInZoneSeconds < 30
    - At most one layer fires per tick
    - hrSmooth is within [min(hrBuffer), max(hrBuffer)]
    - consecutiveInZoneSeconds >= 0 always
    - Same inputs always produce same output (determinism, injected `now`)

---

### Phase 8: Tests — HeartCoach

- [x] **Step 22** — Create `HeartCoachTests/Mocks/MockVoiceFeedbackService.swift`
  - Implements `VoiceFeedbackServiceProtocol`
  - Records `spokenMessages: [CoachingMessage]`, `isMuted: Bool`, `configureAudioSessionCalled: Bool`

- [x] **Step 23** — Create `HeartCoachTests/Mocks/MockWatchBridge.swift`
  - Implements `WatchBridgeProtocol`
  - Records `sentHaptics: [HapticPattern]`, `activateCallCount: Int`
  - `onHRReceived` settable for test injection

- [x] **Step 24** — Create `HeartCoachTests/WorkoutViewModelTests.swift`
  - Uses `MockVoiceFeedbackService`, `MockWatchBridge`, `MockFirebaseService`
  - Tests: start creates session, pause suspends tick, resume resets anti-spam, emergencyStop ends session, session saved after end

---

### Phase 9: Documentation

- [x] **Step 25** — Create `aidlc-docs/construction/unit3-workout-engine/code/code-summary.md`
  - Key implementation notes
  - CoachingEngine placed in HeartRateCoachCore (shared with Unit 4)
  - `now: Date` injection point for PBT determinism
  - HR staleness handled in WorkoutSessionManager, not in CoachingEngine

---

**Total: 25 steps across 9 phases**

Please review and approve this plan, or request changes before code generation begins.
