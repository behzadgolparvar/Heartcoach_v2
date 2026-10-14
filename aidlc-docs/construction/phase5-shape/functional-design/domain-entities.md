# Phase 5 — Domain Entities (Shape)

Technology-agnostic. Pure logic in `HeartRateCoachCore`; app wires the Option A/B + muscle picker, Shape unlock, and the special HIIT cadence. Decisions: Q1–Q10 all A (Q8 checks at ~15s/40s).

## 1. Option + muscle model

### `ShapeOption` (reuse P1b placeholder)
`plyometric` = **Option A** (outdoor/no-equipment); `weights` = **Option B** (treadmill + weights).

### `MuscleGroup` (reuse P1b placeholder)
`chest | back | shoulders | arms | abs | legs`.

### `ShapeSessionChoice` (per-session, Q1/Q2)
- `option: ShapeOption`
- `priority: MuscleGroup?`, `secondary: MuscleGroup?` — exactly 2, ordered (Option B only; nil for Option A)

## 2. Weight-exercise banks (§G, Q3)

### `WeightExercise`
`id`, `name`, `muscle: MuscleGroup`. 30 reps, ~2s/rep (~60s).

### `WeightExerciseBank` (static §G — 6 per muscle, verbatim; flagged for collaborator)
- **chest:** DB chest press, DB fly, chest squeeze press, incline press, single-arm cross-body press, DB pullover
- **back:** bent-over row, single-arm row, reverse fly, DB shrugs, "W" raises, band/DB pull-apart
- **shoulders:** DB shoulder press, lateral raise, front raise, Arnold press, upright row, alternating shoulder press
- **arms:** bicep curl, hammer curl, overhead triceps extension, triceps kickback, concentration-style curl, DB punch/press-out
- **abs:** DB side bend, woodchopper, standing bicycle crunch, overhead reach and twist, high knee with twist, weighted torso twist
- **legs:** (none — uses the P4 plyometric `LegExerciseBank` via the Legs rule)

## 3. Legs rule (Q4)
Per phase, resolve the assigned muscle → if `legs`, draw a plyometric move from `LegExerciseBank` (20 reps); else draw a `WeightExercise` for that muscle (30 reps). A session mixes both types. Option A = always plyometric legs (20 reps).

## 4. Exercise-phase alternation (Q5)

### `ShapeAlternation` (static patterns)
- **Continuous (6 phases, 4-2):** `[priority, secondary, priority, secondary, priority, priority]`
- **HIIT (11 phases 0–10, 6-5):** even index → priority, odd → secondary (priority: 0,2,4,6,8,10; secondary: 1,3,5,7,9)
Each phase index → role → the session's `priority`/`secondary` muscle (Option B). Option A: all phases = legs.

## 5. Shape protocols (§3.1/§3.2, Q7)

### `ShapeProtocolBuilder` (pure) — distinct builder
**Continuous (§3.1):** Block 1 = 6:00 (run 3:50 + exercise 60s + walk); Blocks 2–6 = 5:00 (run 2:50 + exercise 60s + walk); Block 7 = pure run (4:00). 6 exercise phases. %HRR table per §3.1. Buffer → transition → cooldown (reused).
**HIIT (§3.2):** warm-up 3:00 + Exercise Phase 0 (3:00–5:10) + 10 × (run 0:50 + exercise 2:10). 11 exercise phases. Per-round %HRR per §3.2. No buffer; transition → cooldown. Accepts the +10s overage.
Each exercise phase modeled as `.exercise` (60s, carries exercise + reps + muscle) + `.rest` walk; the 0:10 talk/breathing are cues. `PhaseKind.exercise` reused (not scored).

### `FoundationPhase` (reuse) — exercise phase now may carry muscle
Add `muscle: MuscleGroup?` to the exercise phase (for display/coaching); `exercise`/`exerciseReps` already exist (P4).

## 6. Shape-HIIT coaching cadence (Q8)
Shape-HIIT `work` (run, 0:50) phases: 2 zone checks at ~15s and ~40s (not 15s cycle). Shape Continuous = 15s. Safety = 5s. Coaching engine unchanged; only the driver's tick cadence for these phases differs.

## 7. Shape unlock (§E, Q9)

### `ShapeUnlock` (stored on profile)
- `equipmentPreference: ShapeOption` — §E Q1 default (A or B)
- `focusAreas: Set<MuscleGroup>` — §E Q3, pre-fills the per-session picker
- `acknowledgedLevelUpPain: Bool` — §E Q2 safety acknowledgement
- `unlockedAt: Date`
Injury exclusion for Option-A/legs phases reuses the P4 `LevelUpUnlock.injuredJoints` (carried forward); if desired, confirmable at Shape unlock.

## 8. Advancement (Q10)
Level Up complete (60) → present Shape unlock → `currentStage = .shape` + `StageProgress(.shape, 0)`; classification carries over. Shape complete (60) → "Shape complete — Maintain coming soon" (Maintain out of scope). Builder selection: `.shape` → `ShapeProtocolBuilder`, `.levelUp` → Level Up, else Foundation.

## 9. Reuse / out of scope
Reuse: P2 coaching/cooldown/scoring/engine, P3 progression/relapse/minimum, P4 leg bank + `ExerciseSelector` + injury exclusion. Out: milestones/reminders/export/PDF (P6), Maintain.
