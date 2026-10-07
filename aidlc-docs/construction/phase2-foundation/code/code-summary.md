# Phase 2 — Code Summary (Foundation Protocols + Coaching)

**Status:** complete. Core + iOS app build; full suite green (84 tests). SECURITY-03 grep clean. Device Watch/HealthKit verification deferred to Build & Test.

## Pure core (`HeartRateCoachCore`) — Steps 1–4 (committed d7f45c1)
- `Models/FoundationProtocol.swift` — `PhaseKind`, `TargetRange` (%HRR→bpm), `FoundationPhase`, `FoundationProtocol`
- `Models/CooldownStep.swift` — §F 6-step, 120s sequence
- `Engine/FoundationProtocolBuilder.swift` — Continuous (7×300s) / HIIT (warmup + 15×(60/60), 6 intensity blocks) + buffer (Continuous) → transition gate → cooldown
- `Models/CoachingCue.swift` — `CoachingCue`, `CoachingPriority`, `PhraseCategory`, `SeededGenerator`
- `Models/PhrasePool.swift` — phrase pools + no-3×-repeat selection
- `Engine/CoachingSessionState.swift`, `Engine/CoachingEngineV2.swift` — layered tick (BR-2-5/6/7/8/10), v1 `CoachingEngine` untouched
- `Models/SessionScore.swift`, `Engine/SessionScorer.swift` — % time in target over scored phases; tiers 90/75/60/40
- `Engine/BriefingPolicy.swift` — first-4-per-type-per-stage
- Tests: `FoundationProtocolTests`, `CoachingEngineV2Tests`, `SessionScorerTests`, `BriefingPolicyTests` (23)

## Session model + persistence — Step 5
- `Session`: + `scorePercent`, `scoreTier`, `trainingDurationSec`, `sessionFlag`, `cooldownSkipped` (all optional/defaulted → v1 back-compat)
- `HRRecord`: + optional `phaseKind: PhaseKind?`
- `FirestoreService` encode/decode the new fields tolerantly

## v2 session driver + flow switch — Steps 6–9
- `HeartCoach/Workout/FoundationSessionManager.swift` (NEW) — drives the `FoundationProtocol` timeline: 5s safety ticks / 15s coaching, two clocks (training vs total), buffer, **user-paced transition gate** (pauses, waits for `beginCooldown()`), cooldown step playback with voice cues, end-of-training scoring, tier-matched spoken closing. Mirrors v1 manager lifecycle (configureAudioSession, startWatch, haptics, emergencyStop).
- `WorkoutViewModel` — now builds `FoundationSessionManager`; added `awaitingCooldownStart`, `cooldownStepLabel`, `beginCooldown()`; init takes `restingHR`/`maxHR`. v1 `WorkoutSessionManager`/`CoachingEngine` left compiled but off the live path (Q6=A).
- `WorkoutView` — transition-gate overlay ("Begin stretches" / Skip) + cooldown step display.
- `WorkoutPreStartView` — Fartlek card removed (Continuous + HIIT only).
- `WorkoutSummaryView` — score card (% + tier).
- `AppContainer.makeWorkoutViewModel` / `HomeView` — pass `restingHR`/`maxHR` from the profile.

## Security / compliance
- SECURITY-03: no HR/target/score/phrase values in any logging call site (new Phase 2 code has zero logging; 3 pre-existing v1 infra logs print only `error.localizedDescription`).
- SECURITY-01 / own-data / consent inherited; new fields ride the existing session doc. 02/04 N/A.
- PBT (partial): protocol ranges, coaching layers/severity/escalation/rotation, scorer boundaries/exclusions, briefing — all covered.

## Deferred within Phase 2 (flagged for Build & Test / follow-up)
- **§J advanced safety not yet wired into the v2 driver:** sensor-dropout prompt UI, pause 15-min prompt + snoozes, and the **elevated-starting-HR `walk_fallback` sub-protocol** (BR-2-24/25/27). Current driver has: stale-HR→no-signal handling, HR>max safety cue + haptic, pause/resume, cancel-by-training-time via scoring, and `cooldownSkipped`. The richer §J flows are a focused follow-up before TestFlight.
- Spoken pre-session briefing content is gated by `BriefingPolicy` but the briefing *screen/script* is minimal; full scripts can be dropped in without logic change.
- On-device Watch HR + voice + background-session verification (Build & Test).
