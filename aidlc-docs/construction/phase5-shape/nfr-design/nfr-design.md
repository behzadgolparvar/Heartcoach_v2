# Phase 5 — NFR Design (Shape)

How the NFR requirements are realized. Concise; patterns + placements.

## 1. Purity / determinism
- `WeightExerciseBank` is immutable §G data. `ShapeExercisePlanner` and `ShapeProtocolBuilder` are pure functions over value inputs + injected `seed` → reproducible plans/timelines for tests.
- Alternation patterns (4-2 / 6-5) are static constant arrays — one source, indexed by phase.

## 2. Safety patterns
- **Single-source exercise entry:** the planner is the only place exercises enter a Shape session; leg phases go through the P4 `ExerciseSelector.eligible` (injury exclusion + empty-pool safeguard), so an injured joint never yields an excluded plyometric move.
- **Validation gate:** Option B can't start without exactly 2 distinct, ordered muscles (BR-5-2) — enforced before a protocol is built.
- Run-phase HR safety + §J reuse P2 unchanged; `.exercise` phases are low-intensity, non-scored, safety passively watching.

## 3. Reuse (minimize new surface)
- Reuses `PhaseKind.exercise` + `FoundationPhase` (adds optional `muscle`); the P2 phase sequencer, timing, scoring exclusions, §F cooldown all unchanged.
- Run coaching keeps `CoachingEngineV2`; only the **driver's tick cadence** changes for Shape-HIIT runs (2 checks at ~15s/40s) — engine logic untouched, disjoint from the exercise-cue layer by phase kind.
- Progression/relapse/minimum (P3) untouched; builder selection keys on `currentStage`.

## 4. Security (SECURITY-03)
- Banks, planner, builder, unlock, cues contain **no logging**. Code-Gen grep-check over the new types (incl. `ShapeUnlock`, muscle picks, exercise names) → zero hits. `ShapeUnlock` under the own-data doc (SECURITY-01); no new auth/network (02/04 N/A).

## 5. Testability
- Seed injected → reproducible plans. Pure builder → assert §3.1/§3.2 timelines (Block 1 = 6:00; Blocks 2–6 = 5:00; Block 7 pure run; HIIT warm-up + Phase 0 + 10 rounds = 11 exercise phases; +10s overage), %HRR per phase, scored-phase set.
- Alternation + Legs-rule rep counts (legs 20 / weight 30) + Option A all-legs + injury exclusion tested exhaustively.

## 6. Usability
- Per-session Option A/B + muscle picker defaults from `ShapeUnlock`; one-tap on a typical day.
- Every exercise cue carries display text (voice-off); weight phases show "<name> — 30 reps", leg phases "20 reps".
- Shape-complete → "Maintain coming soon" celebratory state.

## 7. Component / placement map
| Concern | Component | Location |
|---|---|---|
| Weight banks | `WeightExercise`, `WeightExerciseBank` | `HeartRateCoachCore` |
| Session choice + alternation | `ShapeSessionChoice`, `ShapeAlternation` | `HeartRateCoachCore` |
| Planner / builder | `ShapeExercisePlanner`, `ShapeProtocolBuilder` | `HeartRateCoachCore` |
| Unlock state | `ShapeUnlock` (on profile) | `HeartRateCoachCore` |
| Builder selection + Shape-HIIT cadence + weight cue | session-driver extension | app `Workout/` |
| Unlock screen + Option A/B + muscle picker | views | app `Views/` |

## 8. Infrastructure Design — SKIPPED
No new infrastructure. Consistent with prior phases.
