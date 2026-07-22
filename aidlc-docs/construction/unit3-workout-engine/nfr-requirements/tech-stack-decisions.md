# Tech Stack Decisions — Unit 3: iPhone Workout Engine

## Language & Platform

| Decision | Choice | Rationale |
|---|---|---|
| Swift version | Swift 5.9 | Consistent with Units 1 and 2 |
| Minimum deployment | iOS 17.0 | Project-wide target |

---

## Tick Loop

| Decision | Choice | Rationale |
|---|---|---|
| Timer implementation | `Task` + `Task.sleep(nanoseconds:)` | Async/await style consistent with rest of app (Q1 — B) |
| Thread | Background (off main thread) | `Task.sleep` runs on cooperative thread pool |
| UI updates from tick | `await MainActor.run { ... }` | Ensures `@Observable` ViewModel properties update on main thread |
| Pause implementation | Cancel the `Task`, store reference | `tickTask?.cancel()` on pause; new `Task` on resume |

### Tick Loop Pattern
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

---

## Voice Coaching

| Decision | Choice | Rationale |
|---|---|---|
| Framework | `AVSpeechSynthesizer` (Apple framework, no SPM) | Built-in TTS; no network required; works offline |
| Voice | `AVSpeechSynthesisVoice(language: "en-US")` | All coaching messages are English; device may be set to other language (Q2 — B) |
| Audio session category | `.playback` with `.duckOthers` option | Ducks background music during coaching cues; resumes after |
| Interruption | `stopSpeaking(at: .immediate)` before new utterance | Prevents overlapping cues |
| Mute bypass | Layer 1 emergency messages always spoken, even when muted | Safety is non-negotiable |

### Audio Session Setup
```swift
try? AVAudioSession.sharedInstance().setCategory(
    .playback,
    mode: .default,
    options: [.duckOthers, .allowBluetooth]
)
try? AVAudioSession.sharedInstance().setActive(true)
```

`.allowBluetooth` ensures AirPods receive the audio. `.duckOthers` lowers music volume during cues.

---

## WatchConnectivity

| Decision | Choice | Rationale |
|---|---|---|
| Send method | `WCSession.default.sendMessage(_:replyHandler:errorHandler:)` | Real-time delivery; appropriate for time-sensitive haptic commands |
| Failure handling | Fire and forget — `errorHandler` logs silently and discards (Q3 — A) | Haptics are time-sensitive; a late retry is worse than no haptic |
| HR receipt | `WCSessionDelegate.session(_:didReceiveMessage:)` | Watch sends HR every ~5s; received on background queue → dispatch to main |

---

## Apple Frameworks Used (No SPM)

| Framework | Purpose |
|---|---|
| `AVFoundation` | `AVSpeechSynthesizer` for voice coaching |
| `WatchConnectivity` | `WCSession` for iPhone ↔ Watch communication |
| `Combine` | Not used for tick loop; may be used for `@Published` wrappers if needed |

No new external SPM dependencies in Unit 3. All frameworks are system-provided.

---

## HR Staleness Tracking

| Property | Value |
|---|---|
| Normal reading interval | ~5 seconds |
| Acceptable gap (one missed reading) | Up to 14 seconds |
| Staleness threshold (signal lost) | 15 seconds |
| Data type | `HRReading` (value: Int, timestamp: Date) from Unit 1 |

---

## PBT Compliance Summary (Unit 3 — Partial Enforcement)

| Rule | Status | Notes |
|---|---|---|
| PBT-02 | Planned | Round-trip: CoachingEngine tick with same state → same output |
| PBT-03 | Planned | Invariants: layer exclusivity, anti-spam, grace period, in-zone counter bounds |
| PBT-07 | Planned | Custom generators: `WorkoutPhase`, `CoachingEngineState`, reuse `HRZones` gen from Unit 1 |
| PBT-08 | Planned | SwiftCheck seed logged on CI |
| PBT-09 | Compliant | SwiftCheck already added as test dependency in Unit 1; reused here |

---

## Security Compliance Summary (Unit 3)

| Rule | Status | Notes |
|---|---|---|
| SECURITY-03 | Planned | No HR values, zone data, or session content in logs |
| SECURITY-11 | Compliant | `hrStream` data treated as sensitive; not sent to third parties |
| SECURITY-15 | Compliant | WCSession errors silently dropped; no raw error codes shown to user |
| All others | N/A | No new auth, network, storage, or infrastructure in Unit 3 |
