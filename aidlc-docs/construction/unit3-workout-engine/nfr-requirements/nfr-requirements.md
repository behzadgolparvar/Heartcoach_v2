# NFR Requirements — Unit 3: iPhone Workout Engine

## NFR Category Assessment

| Category | Applicable | Reason |
|---|---|---|
| Performance | Yes | Tick loop latency, voice synthesis timing, coaching engine speed |
| Reliability | Yes | HR staleness handling, WatchConnectivity resilience, pause/resume correctness |
| Security | Yes | HR stream data privacy (carries forward from Unit 2) |
| Scalability | N/A | Single-user, single-session, in-memory |
| Availability | N/A | On-device; no external service dependency during workout |
| Maintainability | Yes | CoachingEngine PBT coverage (enforced extension) |

---

## Performance Requirements

| Requirement | Target | Rationale |
|---|---|---|
| `CoachingEngine.tick()` execution time | < 5ms | Called every 5 seconds; must not delay next HR record or UI update |
| Voice synthesis latency (first word) | < 500ms after tick | `AVSpeechSynthesizer` typically < 100ms; well within budget |
| Tick loop jitter tolerance | ± 500ms | `Task.sleep` is not real-time; small drift is acceptable for 5s coaching |
| WatchConnectivity send latency | < 200ms | Haptic should fire as close to voice cue as possible |
| UI update after tick | < 16ms (one frame) | `CoachingState` published to `@Observable` ViewModel on `@MainActor` |

**Note**: `CoachingEngine.tick()` is pure math (HR comparison, counter increments) — sub-millisecond in practice. The 5ms target has wide margin.

---

## Reliability Requirements

### HR Staleness Handling

The Apple Watch HR sensor fires approximately every 5 seconds during a workout. Occasional 10-second gaps (one missed reading) are normal sensor behavior and must not trigger a false "no signal" alert.

| Scenario | `lastHRReading` age | Action |
|---|---|---|
| Normal | < 10 seconds | Use reading; coach normally |
| One missed reading | 10–14 seconds | Use last known value; no warning; continue coaching |
| Signal lost | ≥ 15 seconds | Layer 1 fires: "No heart rate signal. Please check your Watch." |

**Implementation**: `WorkoutSessionManager` tracks `lastHRReceived: HRReading` (value + timestamp). Each tick computes `staleness = Date() - lastHRReceived.timestamp` and passes either the current or last-known HR value to `CoachingEngine.tick()`.

### WatchConnectivity Resilience

| Scenario | Behaviour |
|---|---|
| Haptic command delivered | Watch vibrates as expected |
| Haptic command lost (Bluetooth gap) | Silently dropped — fire and forget (Q3 — A) |
| Watch disconnected entirely during workout | HR stream from Watch stops; staleness counter triggers Layer 1 after 15s |
| Watch reconnects | HR resumes; staleness clears; coaching resumes normally |

### Pause / Resume Correctness

| Requirement | Detail |
|---|---|
| Timer suspended on pause | `Task` cancelled; no tick fires while paused |
| Timer restarted on resume | New `Task` created; first tick fires 5 seconds after resume |
| Anti-spam reset on resume | `lastLayer2MessageAt = nil` so a coaching cue fires promptly after resuming |
| `consecutiveInZoneSeconds` reset on pause | In-zone streak is broken by any pause |

---

## Security Requirements

All health data security rules from Unit 2 apply unchanged to Unit 3.

| Rule | Application to Unit 3 |
|---|---|
| SECURITY-03 (no health data in logs) | HR values in `hrStream`, `avgHR`, and `CoachingEngineState` must never appear in logs or crash reports |
| SECURITY-11 (health data classification) | `hrStream` in a completed `Session` is sensitive — handled same as profile data |
| SECURITY-15 (no raw errors to UI) | `WCSession` errors mapped to silent drops; no raw error codes shown to user |

---

## PBT Requirements — CoachingEngine (Enforced Extension)

`CoachingEngine` is the second PBT target (alongside `ZoneCalculator`) per the partial enforcement mode selected in Requirements Analysis (PBT-02, 03, 07, 08, 09 enforced).

### Testable Properties for CoachingEngine

| Property | Category |
|---|---|
| Layer 1 always fires when `hr > HRmax`, regardless of other state | Invariant |
| Layer 2 never fires when `phase.targetZone == nil` | Invariant |
| Layer 2 never fires when `isGracePeriodActive == true` | Invariant |
| Layer 2 never fires within 20 seconds of a previous Layer 2 message | Invariant |
| Layer 3 never fires when `consecutiveInZoneSeconds < 30` | Invariant |
| At most one layer fires per tick | Invariant |
| `hrSmooth` is always within `[min(hrBuffer), max(hrBuffer)]` | Invariant |
| `consecutiveInZoneSeconds` is always ≥ 0 | Invariant |
| Same inputs to `tick()` always produce the same output (determinism) | Idempotence |

### PBT Generators Needed
- `Gen<WorkoutPhase>` — generates phases with/without target zones, with/without grace period
- `Gen<CoachingEngineState>` — generates states with varying buffer, timers, in-zone counters
- `Gen<HRZones>` — reuse from Unit 1 `validProfileGen`

---

## Voice Coaching Requirements

| Requirement | Detail |
|---|---|
| Voice language | Always `AVSpeechSynthesisVoice(language: "en-US")` — regardless of device locale (Q2 — B) |
| Mute support | When muted: voice suppressed; Layer 1 emergency messages ALWAYS spoken |
| Interruption | New message calls `stopSpeaking(at: .immediate)` before speaking |
| Audio session | `AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)` — ducks music during coaching cues |
