# NFR Design Patterns — Unit 3: iPhone Workout Engine

## Pattern 1: Stateless Coaching Engine (Q1 — A)

**Decision**: `CoachingEngine.tick()` is a `static` function. All mutable state lives in a separate value-type struct `CoachingEngineState`, owned and persisted by `WorkoutSessionManager`.

```swift
// In HeartRateCoachCore (extends Unit 1)
struct CoachingEngineState {
    var hrBuffer: [Int] = []           // last 2 HR readings; averaged for hrSmooth
    var lastLayer2MessageAt: Date?     // anti-spam: Layer 2 minimum gap 20s
    var consecutiveInZoneSeconds: TimeInterval = 0  // Layer 3 trigger at ≥30s
}

// Stateless engine — pure function
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

**Rationale**: PBT tests can construct any `CoachingEngineState` directly and call `tick()` without driving the engine through a sequence of ticks to reach that state. The `now: Date` injection point makes time-sensitive invariants (anti-spam, staleness) fully deterministic in tests.

**Caller pattern** (in `WorkoutSessionManager`):
```swift
private var engineState = CoachingEngineState()

func processTick(hr: Int, phase: WorkoutPhase, elapsedInPhase: TimeInterval) {
    let message = CoachingEngine.tick(
        hr: hr, phase: phase, elapsedInPhase: elapsedInPhase,
        state: &engineState, zones: zones
    )
    if let message { voiceFeedback.speak(message) }
}
```

---

## Pattern 2: Tick Loop (Cancel + Recreate)

**Decision**: `Task` + `Task.sleep(nanoseconds: 5_000_000_000)`. Pause = cancel task. Resume = create new task.

```swift
private var tickTask: Task<Void, Never>?

func startTickLoop() {
    tickTask = Task {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { processTick() }
        }
    }
}

func pauseTickLoop() {
    tickTask?.cancel()
    tickTask = nil
}
```

**On pause**: `engineState.consecutiveInZoneSeconds` is reset to `0`. `engineState.lastLayer2MessageAt` is set to `nil` so a coaching cue fires promptly on resume.

---

## Pattern 3: 3-Layer Mutual Exclusion (Early Return)

**Decision**: Layer 1 (Safety) is evaluated first. If it fires, `tick()` returns immediately — Layers 2 and 3 never run. Same for Layer 2 vs Layer 3. Exactly one layer fires per tick, or none.

```swift
// Pseudo-code of tick() body
static func tick(...) -> CoachingMessage? {

    // Update HR buffer (always)
    updateBuffer(hr: hr, state: &state)

    // Layer 1 — Safety (always evaluated first)
    if isHRCritical(state.hrSmooth, zones) {
        return .layer1Safety(...)
    }

    // Layer 2 — Zone Coaching (only if no Layer 1)
    if let zoneMessage = evaluateLayer2(phase, state, zones, elapsedInPhase, now) {
        return zoneMessage
    }

    // Layer 3 — Positive Feedback (only if Layers 1 and 2 both silent)
    if let positiveMessage = evaluateLayer3(phase, state, zones, now) {
        return positiveMessage
    }

    return nil
}
```

---

## Pattern 4: HR Smoothing (2-Reading Average)

**Decision**: `hrBuffer` holds the last 2 raw HR readings. `hrSmooth` is the integer average of all values in the buffer (ceiling rounded, consistent with BR-03 in ZoneCalculator).

```swift
private static func updateBuffer(hr: Int, state: inout CoachingEngineState) {
    state.hrBuffer.append(hr)
    if state.hrBuffer.count > 2 { state.hrBuffer.removeFirst() }
}

static var hrSmooth: Int {
    // computed from state.hrBuffer — ceiling average
    Int(ceil(Double(state.hrBuffer.reduce(0, +)) / Double(state.hrBuffer.count)))
}
```

**Invariant (PBT)**: `hrSmooth` is always within `[min(hrBuffer), max(hrBuffer)]`.

---

## Pattern 5: HR Staleness Tracking

**Decision**: `WorkoutSessionManager` owns `lastHRReceived: HRReading`. Staleness is computed on each tick before calling `CoachingEngine.tick()`. If stale ≥ 15s, passes a sentinel value that triggers Layer 1 "no signal" message.

| `staleness` | Behaviour |
|---|---|
| < 10s | Pass `lastHRReceived.value` to `tick()` normally |
| 10–14s | Pass `lastHRReceived.value` unchanged — no warning |
| ≥ 15s | Pass `hrStaleSentinel` (e.g., `Int.max`) to `tick()` — Layer 1 fires |

This keeps staleness logic outside `CoachingEngineState` (no timestamps in the pure function's state).

---

## Pattern 6: Anti-Spam (Layer 2 Minimum Gap)

**Decision**: `CoachingEngineState.lastLayer2MessageAt: Date?` is compared against `now` in each `tick()`. Layer 2 is suppressed unless `now - lastLayer2MessageAt ≥ 20s` (or it's nil — first message allowed).

```swift
private static func evaluateLayer2(
    phase: WorkoutPhase,
    state: inout CoachingEngineState,
    zones: HRZones,
    elapsedInPhase: TimeInterval,
    now: Date
) -> CoachingMessage? {
    guard phase.targetZone != nil else { return nil }         // no target
    guard elapsedInPhase >= 10.0 else { return nil }          // grace period
    if let last = state.lastLayer2MessageAt,
       now.timeIntervalSince(last) < 20 { return nil }       // anti-spam
    // ... evaluate zone and return message
    state.lastLayer2MessageAt = now
    return message
}
```

---

## Pattern 7: In-Zone Streak Counter (Layer 3)

**Decision**: `consecutiveInZoneSeconds` in `CoachingEngineState` is incremented by 5 each tick the user is in-zone. Reset to 0 on any tick where the user is out-of-zone, paused, or Layer 1 fires.

Layer 3 fires when `consecutiveInZoneSeconds >= 30` (i.e., 6 consecutive in-zone ticks).

**Invariant (PBT)**: `consecutiveInZoneSeconds >= 0` always.

---

## Pattern 8: Voice Interruption

**Decision**: Before every `speak()` call, call `stopSpeaking(at: .immediate)`. Prevents overlapping audio when a new message arrives before the previous finishes.

```swift
func speak(_ message: CoachingMessage) {
    synthesizer.stopSpeaking(at: .immediate)
    let utterance = AVSpeechUtterance(string: message.text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    synthesizer.speak(utterance)
}
```

**Layer 1 mute bypass**: Emergency messages always call `speak()` regardless of the user's mute preference. All other messages check the mute flag first.

---

## Pattern 9: Audio Session Setup

**Decision**: Audio session configured once when the workout starts (not per-utterance).

```swift
func configureAudioSession() {
    try? AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: [.duckOthers, .allowBluetooth]
    )
    try? AVAudioSession.sharedInstance().setActive(true)
}
```

`.duckOthers` lowers music volume during coaching cues. `.allowBluetooth` ensures AirPods receive audio.

---

## Pattern 10: WatchConnectivity Fire-and-Forget

**Decision**: `sendMessage` with a no-op error handler. No retry logic. Late haptic delivery is worse than no haptic.

```swift
func sendHaptic(_ pattern: HapticPattern) {
    guard WCSession.default.isReachable else { return }
    WCSession.default.sendMessage(
        ["haptic": pattern.rawValue],
        replyHandler: nil,
        errorHandler: { _ in }   // silently drop
    )
}
```

---

## PBT Compliance

| Rule | Pattern |
|---|---|
| PBT-02 (determinism) | `tick()` is pure static; `now: Date` injected — same inputs always yield same output |
| PBT-03 (invariants) | 9 invariants defined in nfr-requirements.md; all testable via `CoachingEngineState` construction |
| PBT-07 (generators) | `Gen<CoachingEngineState>`, `Gen<WorkoutPhase>`, reuse `Gen<HRZones>` from Unit 1 |
| PBT-08 (seed logging) | SwiftCheck seed logged on test failure — inherited from Unit 1 test setup |
| PBT-09 (dependency) | SwiftCheck already in `HeartRateCoachCore` test target |

---

## Security Compliance

| Rule | Applied in Pattern |
|---|---|
| SECURITY-03 (no health data in logs) | `errorHandler` in Pattern 10 discards without logging; `hrBuffer` and `hrSmooth` never passed to `print()` / `os_log()` |
| SECURITY-11 (health data classification) | `CoachingEngineState` treated as in-memory sensitive data; not persisted |
| SECURITY-15 (no raw errors to user) | WCSession errors silently dropped (Pattern 10) |
