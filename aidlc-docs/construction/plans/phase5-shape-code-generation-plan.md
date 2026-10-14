# Phase 5 — Code Generation Plan (single source of truth)

**Unit:** Shape · **Type:** brownfield · **Branch:** new_design_Sep_2026
**Design source:** `construction/phase5-shape/{functional-design,nfr-requirements,nfr-design}/*`
**Answers:** Q1–Q10 all A (Q8 checks ~15s/40s). **Rule:** keep the app building; reuse P2 engine / P3 progression / P4 leg bank + selector; Foundation & Level Up paths unchanged.

## Milestone
At Level Up 60, the Shape unlock (equipment pref + Level-Up-pain ack + focus areas) appears; completing it switches to Shape. Each Shape session: pick Option A or B (B → pick & rank 2 muscles), the engine builds the §3.1/§3.2 timeline with weight/plyometric exercises alternated 4-2 (Continuous) / 6-5 (HIIT) under the Legs rule, coaches runs (Shape-HIIT at 2 checks/50s) + exercises, cooldown + score, and progression advances Shape's counter. At Shape 60 → "Maintain coming soon".

## Naming / reuse
New core: `WeightExercise`, `WeightExerciseBank`, `ShapeSessionChoice`, `ShapeAlternation`, `ShapeExercisePlanner`, `ShapeProtocolBuilder`, `ShapeUnlock`; `FoundationPhase.muscle`. Reuse `ShapeOption`/`MuscleGroup` (P1b), `LegExerciseBank`/`ExerciseSelector`/`LevelUpUnlock` (P4), `FoundationProtocol`/manager, `CoachingEngineV2`, `SeededGenerator`, `ProgressionEngine`.

---

## Step 1 — Weight banks + Shape types (`HeartRateCoachCore`)  [x]
- [x] `Models/WeightExercise.swift` — `WeightExercise { id, name, muscle }`
- [x] `Models/WeightExerciseBank.swift` — §G 5 banks × 6 (flagged); `exercises(for:)`
- [x] `Models/ShapeSessionChoice.swift` — option + priority/secondary (exactly-2 helpers)
- [x] Add `FoundationPhase.muscle: MuscleGroup?` (default nil)

## Step 2 — Planner + builder (`HeartRateCoachCore`, pure)  [x]
- [x] `Engine/ShapeAlternation.swift` — 4-2 (Continuous) / 6-5 (HIIT) role patterns
- [x] `Engine/ShapeExercisePlanner.swift` — role→muscle→exercise (Legs rule: legs→plyo 20 via `ExerciseSelector`; else weight 30), seeded, injury-excluded
- [x] `Engine/ShapeProtocolBuilder.swift` — §3.1 Continuous (Block 1 = 6:00; 2–6 = 5:00; Block 7 pure run) + §3.2 HIIT (warm-up + Exercise Phase 0 + 10 rounds, 11 exercise phases, +10s overage) + buffer/transition/cooldown
- [x] `Models/ShapeUnlock.swift` — equipmentPreference/focusAreas/acknowledgedLevelUpPain/unlockedAt; add to `UserProfileV2` (tolerant Codable)

## Step 3 — Core tests (app test target; PBT partial)  [x]
- [x] `ShapeAlternationTests` / `ShapeExercisePlannerTests` — 4-2 & 6-5 exact; role→muscle; Legs rule rep counts (20/30); Option A all-legs; injury exclusion; seeded determinism
- [x] `ShapeProtocolBuilderTests` — Continuous block timings; HIIT 11 exercise phases + structure; %HRR per phase; scored-phase set
- [x] `WeightExerciseBankTests` — 6 per muscle; legs empty
- [x] `UserProfileV2` round-trip incl. `ShapeUnlock`

## Step 4 — Session-manager extension (app)  [x]
- [x] Builder selection: `.shape` → `ShapeProtocolBuilder` (passing planned exercises); Shape-HIIT run phases use 2-checks (~15s/40s) cadence; weight-exercise cue ("<name> — 30 reps")
- [x] `WorkoutViewModel`: carry Shape choice; build Shape protocol at start

## Step 5 — Shape unlock + per-session pickers + advance (app)  [x]
- [x] `ShapeUnlockView` (equipment pref, Level-Up-pain ack, focus areas) on Level Up-complete state; store `ShapeUnlock`, advance `currentStage=.shape`
- [x] Per-session Option A/B screen + (B) muscle pick-and-rank picker (default from unlock)
- [x] `HomeViewModel`: Level Up-complete → unlock entry; Shape assignment; Shape-complete "Maintain coming soon"

## Step 6 — Build, test, verify  [x]
- [x] `xcodegen generate`; build iOS + core; full test suite
- [x] **SECURITY-03 grep:** no muscle/selection/assignment values in any logging call site
- [x] Code summary in `construction/phase5-shape/code/`

---

### Scope estimate
~6 steps, ~18–22 files (most new in core; session-manager + unlock/picker screens are the app changes). Pure core (Steps 1–3) lands first and is fully testable; Step 4–5 are additive (Foundation/Level Up paths untouched; new behavior only on `.shape` stage).

### Traceability
FR-4 (Shape protocols), FR-8 (muscle/exercise data), §Phase3/§E/§G · BR-5-1…19 · Phase 5 of the v5 plan. Security: SECURITY-03 grep gate, own-data/consent inherited. PBT: planner, builder, banks, serialization.
