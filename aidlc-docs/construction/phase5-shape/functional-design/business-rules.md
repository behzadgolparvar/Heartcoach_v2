# Phase 5 — Business Rules (Shape)

`BR-5-*` namespace. Pure/deterministic and PBT-targetable unless noted.

## Daily choice + selection
- **BR-5-1 (Option A/B per session, Q1):** chosen at every session start; default = `ShapeUnlock.equipmentPreference` (and/or last choice). Not locked.
- **BR-5-2 (muscle pick, Q2):** Option B requires **exactly 2** distinct muscle groups, ordered (priority, secondary); pre-filled from `ShapeUnlock.focusAreas`. Validation rejects ≠2 or duplicates. Option A needs no muscles.

## Exercise content + Legs rule
- **BR-5-3 (weight banks, Q3):** `WeightExerciseBank` = §G, 6 per muscle (chest/back/shoulders/arms/abs); 30 reps, ~2s/rep. Flagged for collaborator confirmation.
- **BR-5-4 (Legs rule, Q4):** for a phase whose assigned muscle is `legs` → draw a plyometric move from `LegExerciseBank` (20 reps, injury-excluded); otherwise draw a `WeightExercise` of that muscle (30 reps). Option A → every phase is plyometric legs (20 reps).
- **BR-5-5 (selection):** per muscle/leg pool, draw via seeded no-repeat (`ExerciseSelector` for legs; analogous seeded pick for weights), reshuffle on exhaustion.

## Alternation (Q5)
- **BR-5-6 (Continuous 4-2):** phase roles `[P,S,P,S,P,P]` (priority = phases 1,3,5,6; secondary = 2,4).
- **BR-5-7 (HIIT 6-5):** phase index even → priority, odd → secondary (0–10 → priority 0,2,4,6,8,10 = 6; secondary 1,3,5,7,9 = 5).
- **BR-5-8 (role → muscle):** Option B maps role→chosen muscle then BR-5-4 picks the exercise. Option A ignores roles (all legs).

## Protocols (§3.1/§3.2, Q7)
- **BR-5-9 (Continuous):** Block 1 = 6:00 (run 230s + exercise 60s + walk 70s); Blocks 2–6 = 5:00 (run 170s + exercise 60s + walk 70s); Block 7 = pure run 240s. %HRR per §3.1 (50–60 … 75–85). 6 exercise phases. Buffer(30s) → transition → cooldown.
- **BR-5-10 (HIIT):** warm-up 180s + Exercise Phase 0 (exercise 60s + walk, ~130s) + 10 × (run 50s + exercise phase 130s[talk/exercise 60s/rest/walk]). 11 exercise phases (0–10). Per-round %HRR per §3.2. No buffer; transition → cooldown. +10s overage accepted.
- **BR-5-11 (exercise not scored):** `.exercise` phases excluded from scoring (reuses P2 BR-2-12). Scored = warm-up + run `block`/`work`.

## Coaching (Q8)
- **BR-5-12 (Shape-HIIT cadence):** `work` run phases (50s) → 2 zone checks at ~15s and ~40s; Shape Continuous → 15s; safety → 5s everywhere. Engine logic unchanged.
- **BR-5-13 (exercise cues):** reuse the P4 exercise-cue layer (intro + rep target + switch-legs for unilateral plyometric); weight exercises announce name + 30 reps.

## Unlock + advancement (Q9/Q10)
- **BR-5-14 (Shape unlock):** on Level Up completion, present §E: equipment pref (Q1 default), Level-Up-pain acknowledgement (Q2 safety), focus areas (Q3). Store `ShapeUnlock`.
- **BR-5-15 (advance):** Level Up `sessionsCompleted == 60` + unlock → `currentStage = .shape`, `stageProgress[.shape] = StageProgress(.shape, 0)`. Classification unchanged.
- **BR-5-16 (Shape complete):** at Shape 60, show "Shape complete — Maintain coming soon"; no further stage (Maintain out of scope). Assignment keeps Sub-Phase 3.
- **BR-5-17 (builder selection):** `.shape` → `ShapeProtocolBuilder`; `.levelUp` → Level Up; else Foundation.

## Progression reuse
- **BR-5-18:** Shape reuses P3 `ProgressionEngine` unchanged (assignment/advance/relapse/minimum on Shape's counter; §B track from classification).

## Security (inherited, blocking)
- **BR-5-19:** muscle selections, exercise picks, assignments are user data — never console/analytics-logged (SECURITY-03). `ShapeUnlock` persists under the own-data `v2profile` doc; no new auth surface.
