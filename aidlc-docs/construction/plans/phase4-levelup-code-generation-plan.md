# Phase 4 — Code Generation Plan (single source of truth)

**Unit:** Level Up · **Type:** brownfield · **Branch:** new_design_Sep_2026
**Design source:** `construction/phase4-levelup/{functional-design,nfr-requirements,nfr-design}/*`
**Answers:** Q1–Q9 all A. **Rule:** keep the app building; reuse P2 session engine / P3 progression; Foundation path unchanged.

## Milestone
At Foundation 60, the Level Up unlock (injury pre-filled from onboarding + comfort subset) appears; completing it switches to Level Up. Level Up sessions build the reworked Continuous (run/exercise/walk blocks; Block 7 pure run) and HIIT (§2.2: warm-up + exercise block + 10×3:00), insert leg exercises excluded by injury, coach runs via CoachingEngine v2 and exercises via a synced rep-count layer, then cooldown + score as usual. Progression (P3) advances Level Up's own 60-counter.

## Naming / reuse
New core: `LegExercise`, `ExerciseMode`, `LegJoint`, `LegExerciseBank`, `LevelUpUnlock`, `ExerciseSelector`, `LevelUpProtocolBuilder`; `PhaseKind.exercise` + `FoundationPhase.exercise`. Reuse `FoundationProtocol`/manager, `CoachingEngineV2`, `SeededGenerator`, `ProgressionEngine`, `ProgramState`/`StageProgress`, P1b `jointIssues`, `CooldownStep`.

---

## Step 1 — Leg bank + exercise types (`HeartRateCoachCore`)  [x]
- [x] `Models/LegExercise.swift` — `LegExercise`, `ExerciseMode` (bilateral 30s/15, unilateral 32s/8-per-leg), `LegJoint` (knee/hip/ankle) + `JointIssue→LegJoint` map
- [x] `Models/LegExerciseBank.swift` — §G 8 exercises with mode + joint tags (flagged defaults)

## Step 2 — Protocol model extension (`HeartRateCoachCore`)  [x]
- [x] Add `PhaseKind.exercise` (not scored); add `FoundationPhase.exercise: LegExercise?` (default nil, back-compat)

## Step 3 — Selector + Level Up builder (`HeartRateCoachCore`, pure)  [x]
- [x] `Engine/ExerciseSelector.swift` — `eligible(bank:unlock:)` (joint exclusion + comfort subset); `sequence(eligible:count:seed:)` (no-repeat shuffle, empty-pool safeguard)
- [x] `Engine/LevelUpProtocolBuilder.swift` — Continuous (§2.1 internal timeline; Block 7 pure run) + HIIT (§2.2 10×3:00) emitting run/exercise/walk phases + buffer/transition/cooldown
- [x] `Models/LevelUpUnlock.swift` — injuredJoints/comfortable/approvedExerciseIDs/unlockedAt; add optional section to `UserProfileV2` (tolerant Codable)

## Step 4 — Core tests (app test target; PBT partial)  [x]
- [x] `ExerciseSelectorTests` — exclusion per joint; comfort subset; no-repeat sequence (seed); counts 6/11; empty-pool safeguard
- [x] `LevelUpProtocolBuilderTests` — Continuous block timeline + Block 7 pure run; HIIT §2.2 structure; %HRR per phase; scored-phase set; mode→duration/reps
- [x] `LegJointMappingTests` — `jointIssues→LegJoint`
- [x] `UserProfileV2` round-trip incl. `LevelUpUnlock`

## Step 5 — Exercise-cue coaching + builder selection (app)  [x]
- [x] Extend `FoundationSessionManager`: select builder by `currentStage`; on `.exercise` phases emit intro + synced rep count (+ "switch legs" unilateral) + slow-walk/next cues; run phases keep `CoachingEngineV2`
- [x] Surface the current exercise + rep progress in the published snapshot

## Step 6 — Level Up unlock + stage advance (app)  [x]
- [x] `LevelUpUnlockView` (+ small VM): injury Q pre-filled from `jointIssues`, comfort Q + subset picker; injury caution modal (BR-4-6)
- [x] On Foundation-complete state (P3 Q8): show unlock → on finish store `LevelUpUnlock`, set `currentStage=.levelUp` + `StageProgress(.levelUp,0)`, persist
- [x] Home: when `currentStage==.levelUp`, assign + run Level Up sessions (feed selector picks into the builder); show exercise in WorkoutView

## Step 7 — Build, test, verify  [x]
- [x] `xcodegen generate`; build iOS + core; full test suite
- [x] **SECURITY-03 grep:** no injury/joint/exercise/assignment values in any logging call site
- [x] Code summary in `construction/phase4-levelup/code/`

---

### Scope estimate
~7 steps, ~16–20 files (most new in core; the session-manager exercise-cue layer + unlock screen are the app changes). Pure core (Steps 1–4) lands first and is fully testable; the session-manager extension (Step 5) is the main live-surface change, additive (Foundation path untouched; new behavior only on `.exercise` phases / `.levelUp` stage).

### Traceability
FR-4 (Level Up protocols), FR-8 (exercise data), §E/§G · BR-4-1…17 · Phase 4 of the v5 plan. Security: SECURITY-03 grep gate, own-data/consent inherited. PBT: selector, builder, mapping, serialization.
