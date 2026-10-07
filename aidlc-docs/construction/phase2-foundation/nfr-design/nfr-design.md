# Phase 2 — NFR Design (Foundation Protocols + Coaching)

How the NFR requirements are realized in the design. Concise; maps to concrete patterns and code placements.

## 1. Real-time performance patterns
- **Pure, allocation-free tick:** `CoachingEngineV2.tick` takes value inputs (hr, sessionSec, phase snapshot, state) and returns an optional message. Phrase pools are preallocated constants; selection indexes into them — no per-tick heap growth over a 37-min session.
- **Build-once timeline:** `FoundationProtocolBuilder.build` runs at session start and yields an immutable `WorkoutProtocol`; the tick loop reads it, never rebuilds. bpm ranges precomputed from HRR once.
- **Deferred scoring:** `SessionScorer` runs a single linear pass at training end — off the hot path, so it never competes with live coaching/safety.
- **Cadence reuse:** the 15s/5s timers are the existing v1 session-manager timers; no new scheduler.

## 2. Safety liveness pattern (blocking)
- Safety is the **highest priority layer** and evaluated on the independent **5s** sub-check, so a coaching-tick cost can never delay an emergency stop (BR-2-5/23).
- Safety is **suppressed only** in explicitly user-informed states (sensor dropout, pause); every other phase — including buffer/transition/cooldown — keeps it live.
- Emergency stop reuses the v1 path (deactivate Watch bridge + emergency haptic), already covered by `WorkoutViewModelTests`.

## 3. Reliability / lifecycle patterns
- **Complete-at-training-end:** scoring + session finalization happen when the last scored phase ends, so anything after (gate/cooldown) can be interrupted without losing a scored session (BR-2-20).
- **Transition-gate timeout:** the gate is a bounded wait — a watchdog finalizes the session (`cooldownSkipped = true`) if the user never taps, so the flow can't hang.
- **Two independent clocks** isolate scoring time from displayed duration; the gate pauses only `totalElapsedSec` (BR-2-22) — scoring math never sees gate/idle time.
- **Offline-tolerant persistence:** session + phase-tagged `hr_stream` go through the v1 queued-write path (`SessionSaveOutcome`); a save failure queues rather than loses data.
- **Dropout resume-in-place:** data-gap flag + safety-unavailable warning reuse v1 behavior.

## 4. Data-volume pattern
- `hr_stream` stays a single compact encoded blob on the session doc (v1 pattern), now with a 1-byte-ish `phase` tag per record. No new collection, no fan-out, no pagination at single-user scale.

## 5. Security patterns (SECURITY-03 primary)
- **No value-emitting logs:** HR, target ranges, scores, and phrase text are never passed to `print`/`os_log`/analytics. Code-Gen gets an explicit grep-check over the new types (`CoachingEngineV2`, `SessionScorer`, `FoundationProtocolBuilder`, score/phrase fields) → must be zero logging hits, same gate used in Phase 1b.
- **Same storage boundary:** new session/score/`hr_stream` fields persist under the existing `users/{uid}` tree — own-data rules + consent inherited; no new auth/network surface (SECURITY-01 satisfied; 02/04 N/A).

## 6. Testability patterns
- **Seeded RNG injected** into `CoachingEngineV2` (not global random) → reproducible phrase sequences for PBT (BR-2-9).
- **Determinism:** engine + scorer + builder are pure functions of inputs → exhaustive/property tests without mocks (boundaries: ±5 severity, 89/90·74/75·59/60·39/40 tiers, 0–4 briefing).
- v1 engine untouched (Q6=A) → existing coaching tests stay green while v2 is built in parallel.

## 7. Usability pattern
- Every emitted `CoachingMessage` carries display `text`; the in-session view renders it regardless of mute (voice-off fallback). Cooldown steps + the "Begin" gate are on-screen controls, operable silently.

## 8. Component/placement map
| Concern | Component | Location |
|---|---|---|
| Protocol timeline + bpm ranges | `FoundationProtocolBuilder`, `WorkoutProtocol`, `ProtocolPhase`, `TargetRange` | `HeartRateCoachCore` |
| Coaching | `CoachingEngineV2`, `PhrasePool`, `CoachingState` | `HeartRateCoachCore` |
| Scoring | `SessionScorer`, `SessionScore`, `ScoreTier` | `HeartRateCoachCore` |
| Briefing gate | `BriefingPolicy` | `HeartRateCoachCore` |
| Session orchestration (phases, two clocks, gate, safety/edge) | workout session manager | app |
| Manual picker / in-session UI / cooldown + gate / summary | views | app `Views/` |
| Persistence (`phase` tag, score fields, `session_flag`) | `FirestoreService` | app |

## 9. Infrastructure Design — SKIPPED
No new infrastructure (reuses Firebase, HealthKit, Watch targets, audio/haptics). Consistent with Phase 1 / 1b.
