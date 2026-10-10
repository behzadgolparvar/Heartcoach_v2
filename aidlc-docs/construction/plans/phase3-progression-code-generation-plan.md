# Phase 3 — Code Generation Plan (single source of truth)

**Unit:** Progression & Assignment · **Type:** brownfield · **Branch:** new_design_Sep_2026
**Design source:** `construction/phase3-progression/{functional-design,nfr-requirements,nfr-design}/*`
**Answers:** Q1–Q4=A, Q5=B (spec-literal relapse), Q6–Q9=A. **Rule:** keep the app building at every step; reuse P2 `FoundationSessionManager` unchanged.

## Milestone
Home shows "Today's session: <type> · Session N of 60" (assigned by the engine) with a Start button + a "Choose a different workout" override; completing a qualifying session advances the counter and re-assigns; a gap applies §C push-back (positive framing); a one-tap 15-min minimum walk resets the relapse clock without advancing; at 60 the UI shows "Foundation complete — Level Up coming soon".

## Naming / reuse
New core: `ProgressionTables`, `SessionRatio`, `SessionAssignment`, `ProgressionTrack`, `RelapseBand`, `RelapseOutcome`, `ProgressionEngine`. Reuse `UserProfileV2`, `ProgramState`/`StageProgress`, `MentalityLean`, `TrainingGoal`, `WorkoutType`, `Session`/`sessionFlag`, P2 `FoundationSessionManager`.

---

## Step 1 — Progression data + types (`HeartRateCoachCore`)  [x]
- [x] `Models/SessionRatio.swift` — `hiit`/`continuous` + `cycle` (HIIT front-loaded expansion, Q1)
- [x] `Models/ProgressionTrack.swift` — enum + `resolve(experience:goals:)` (Q2)
- [x] `Engine/ProgressionTables.swift` — §B tables (Beginner-FWL / Intermediate / Advanced × lean × sub-phase) + Routine/Cardio marker
- [x] `Models/SessionAssignment.swift` — type, sessionNumber, subPhase, ratio?, isStageComplete
- [x] `Models/RelapseBand.swift` — band enum + `RelapseOutcome`

## Step 2 — ProgramState date field (`HeartRateCoachCore`)  [x]
- [x] Add `ProgramState.lastCountedSessionDate: Date?` (optional, back-compat init default); keep Codable tolerant

## Step 3 — ProgressionEngine (`HeartRateCoachCore`, pure)  [x]
- [x] `Engine/ProgressionEngine.swift`:
  - `assign(profile:) -> SessionAssignment` (track → subPhase → ratio cycle index / Routine-Cardio 1-in-4; stage-complete clamp) — BR-3-1..4, 11
  - `advance(program:sessionFlag:trainingDurationSec:date:) -> ProgramState` (count only qualifying; clamp 60; stamp date) — BR-3-5/6
  - `applyRelapse(program:now:) -> (ProgramState, RelapseOutcome)` (Q5=B plain subtraction / reset→0; once-per-gap stamp) — BR-3-7/8
  - `registerMinimumWalk(program:now:) -> ProgramState` (stamp date only) — BR-3-9

## Step 4 — Core tests (app test target; PBT partial)  [x]
- [x] `ProgressionTablesTests` — every §B cell matches spec
- [x] `ProgressionEngineTests` — assignment across tracks/leans/sub-phases; ratio-cycle spacing; Routine/Cardio 1-in-4 (outcome) vs pure Continuous; multi-goal track resolution (Q2); advance gating (counts/excludes flags, clamp 60); relapse bands + plain subtraction crossing sub-phases + >1mo→0 + once-per-gap; minimum walk stamps date, no advance

## Step 5 — Minimum walk flow (app)  [x]
- [x] `Workout/MinimumWalkManager.swift` — timed 8-fast/7-slow with voice/timer cues (no HR coaching, no scoring); produces a `minimum_walk`-flagged `Session`
- [x] Minimal `MinimumWalkView`

## Step 6 — Home integration (app)  [x]
- [x] `HomeViewModel`: compute `assignment` via `ProgressionEngine.assign`; apply relapse on load (persist program + surface positive message); expose override + minimum entry
- [x] On session completion: call `advance`, persist program; on 60 → Foundation-complete state
- [x] `HomeView`: "Today's session" card (type + N of 60) + Start + "Choose a different workout" override + "Do your 15-min minimum" + Foundation-complete state
- [x] Route Start → existing `WorkoutPreStartView`/`FoundationSessionManager` with the assigned (or overridden) type; make the P2 picker the override path

## Step 7 — Persistence + wiring  [x]
- [x] `FirestoreService`: persist `program` incl. `lastCountedSessionDate` (already within `v2profile` Codable — verify round-trip); recognize `minimum_walk` flag
- [x] Ensure session-complete writes the program update (via Home/VM)

## Step 8 — Build, test, verify  [x]
- [x] `xcodegen generate`; build iOS + core; full test suite
- [x] **SECURITY-03 grep:** no progression/date/assignment values in any logging call site
- [x] Code summary in `construction/phase3-progression/code/`

---

### Scope estimate
~8 steps, ~14–18 files (most new in core; Home integration is the main app change). Pure core (Steps 1–4) lands first and is fully testable; Home wiring (Step 6) is the only live-surface change and is additive (it sits in front of the existing workout flow).

### Traceability
FR-3 (progression/assignment), FR-3b (relapse), FR-12 (non-negotiable minimum) · BR-3-1…12 · Phase 3 of the v5 plan. Security: SECURITY-03 grep gate, own-data/consent inherited. PBT: tables, assignment, advancement, relapse, minimum.
