# Phase 2 — Code Generation Plan (single source of truth)

**Unit:** Foundation Protocols + Coaching + Cooldown + Scoring · **Type:** brownfield · **Branch:** new_design_Sep_2026
**Design source:** `construction/phase2-foundation/{functional-design,nfr-requirements,nfr-design}/*`
**Answers:** Q1–Q11 all A (Q8 A + user-paced transition gate).
**Rule:** keep the app building at every step. v1 coaching/workout engine stays **untouched and compiled** (Q6=A); the workout flow switches to v2 only at Step 8.

## Milestone
Manually pick Foundation Continuous or HIIT → run it end-to-end with CoachingEngine v2 (per-block bpm targets, severity, escalation, transitions, briefing, in-zone), the 30s buffer (Continuous) → user-paced "ready to stretch" gate → mandatory 2-min cooldown → session scored (% in target → tier) with spoken + visual summary → saved with phase-tagged `hr_stream`. Fartlek gone from the picker. Safety/edge (§J) intact.

## Naming (avoid v1 collisions)
New v2 types: `FoundationProtocol`/`FoundationPhase`/`TargetRange`/`PhaseKind`, `CoachingEngineV2`, `CoachingCue` (not `CoachingMessage`), `CoachingSessionState` (not `CoachingState`), `PhrasePool`/`PhraseCategory`, `SessionScorer`/`SessionScore`/`ScoreTier`, `BriefingPolicy`. **Reuse** existing `WorkoutType` (use `.continuous`/`.hiit`, ignore `.fartlek`), `HapticPattern`, `ZoneCalculator`, `UserProfileV2`, `StageProgress`.

---

## Step 1 — Protocol model + builder (`HeartRateCoachCore`)  [x]
- [x] `Models/FoundationProtocol.swift` — `PhaseKind`, `TargetRange` (pct→bpm via BR-2-1), `FoundationPhase`, `FoundationProtocol` (+ `trainingDurationSec`)
- [x] `Engine/FoundationProtocolBuilder.swift` — build Continuous (7×300s table) + HIIT (warmup + 15×(60/60), 6 intensity blocks); append buffer (Continuous) → transition gate (nil-duration) → 6 cooldown steps (BR-2-2/3)
- [x] `Models/CooldownStep.swift` — fixed §F 6-step sequence

## Step 2 — Coaching engine v2 (`HeartRateCoachCore`)  [x]
- [x] `Models/CoachingCue.swift` (text, category, priority, atSec, optional haptic), `PhraseCategory`, `CoachingPriority`
- [x] `Models/PhrasePool.swift` — pools (off-zone minor/major × low/high, in-zone, transitions, "N left", briefing, closing-by-tier) + no-3×-repeat selection with injected seeded RNG (BR-2-9)
- [x] `Engine/CoachingSessionState.swift` — recent phrases/pool, off-run length, in-zone per-block progress, RNG
- [x] `Engine/CoachingEngineV2.swift` — priority ladder tick (BR-2-5/6/7/8/10); pure; v1 `CoachingEngine` left intact

## Step 3 — Scoring + briefing (`HeartRateCoachCore`)  [x]
- [x] `Models/SessionScore.swift` — `SessionScore`, `ScoreTier` (BR-2-14 cutoffs), closing-pool mapping
- [x] `Engine/SessionScorer.swift` — scored-phase filter + in-range per-second count (BR-2-12/13), per-zone tally
- [x] `Engine/BriefingPolicy.swift` — mandatory while <4 scored sessions of type in current stage (BR-2-11)

## Step 4 — Core tests (app test target; PBT partial)  [x]
- [x] `FoundationProtocolTests` — bpm ranges match spec table across profiles; phase durations sum to spec totals; HIIT 6-block grouping
- [x] `CoachingEngineV2Tests` — priority ordering; off-zone severity/direction exhaustive around ±5 (BR-2-6); escalation 30/60s; no-3×-repeat under fixed seed; in-zone once-per-block
- [x] `SessionScorerTests` — tier boundaries (89/90, 74/75, 59/60, 39/40); rest/buffer/transition/cooldown excluded; all-in/all-out extremes
- [x] `BriefingPolicyTests` — 0–4 boundary per type per stage; walk_fallback/<20-min don't count

## Step 5 — Session model + persistence  [x]
- [x] Extend `Session` (+ `scorePercent`, `scoreTier`, `trainingDurationSec`, `totalDurationSec`, `cooldownSkipped`; `session_flag` continuous/hiit/walk_fallback)
- [x] Extend `HRRecord` with `phase: PhaseKind`
- [x] `FirestoreService` encode/decode new fields (tolerant); `MockFirebaseService` updated

## Step 6 — v2 session driver (app)  [x]
- [x] `WorkoutEngineV2` (or extend session manager): phase sequencing over `FoundationProtocol`, 15s coaching / 5s safety ticks, two clocks (training vs total), buffer, **transition gate** (pause total clock, record `transition`, watchdog timeout), cooldown step playback
- [x] Emit `CoachingCue` → voice + on-screen text; append phase-tagged `HRRecord`
- [x] Complete + score at end of training (BR-2-20); finalize after gate/cooldown or timeout

## Step 7 — Safety & edge (§J) in the driver  [x]
- [x] Emergency stop (HR>maxHR, reuse v1 bridge/haptic) live in all phases except dropout/pause
- [x] Sensor dropout (20s), pause/resume (15-min, 3×10 snoozes), cancel (≥20 scored/<20 discard on training time), elevated-HR walk_fallback

## Step 8 — Wire the workout flow to v2 (the switch)  [x]
- [x] `WorkoutViewModel` drives `WorkoutEngineV2` instead of v1 `WorkoutPhaseSequencer`+`CoachingEngine`
- [x] Manual picker (Home/`WorkoutPreStartView`): Continuous + HIIT only (remove Fartlek from selection)
- [x] Briefing screen (skippable per BriefingPolicy); cooldown UI (step list + "Begin" gate); updated summary (percent, tier, per-zone)
- [x] v1 engine/types remain compiled but no longer on the live path

## Step 9 — Consumer updates + tests  [x]
- [x] Update `WorkoutSummaryViewModel`/`WorkoutView`/`HomeViewModel` for score+tier+cooldown
- [x] Update/extend `WorkoutViewModelTests` for v2 driver (start→tick→cooldown→score); keep v1 engine tests green

## Step 10 — Build, test, verify  [x]
- [x] `xcodegen generate`; build iOS + core; full test suite
- [x] **SECURITY-03 grep:** no HR/target/score/phrase values in any logging call site
- [x] Code summary in `construction/phase2-foundation/code/`
- [x] (Device Watch/HealthKit verification noted for Build&Test before any TestFlight)

---

### Scope estimate
~10 steps, ~20–25 files (most new in core; the app-side flow switch in Steps 6–8 is the main risk). Pure core (Steps 1–4) lands first and is fully testable without touching the running app; the flow switch (Step 8) is the one irreversible-feeling change, mitigated by keeping v1 compiled.

### Traceability
FR-4 (protocols), FR-5 (coaching), FR-6 (scoring), FR-6b (cooldown), FR-9 (safety) · BR-2-1…28 · Phase 2 of the v5 plan. Security: SECURITY-03 grep gate, own-data/consent inherited. PBT: builder, engine, scorer, briefing.
