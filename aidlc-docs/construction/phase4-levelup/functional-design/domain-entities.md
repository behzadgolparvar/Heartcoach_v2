# Phase 4 — Domain Entities (Level Up)

Technology-agnostic. Pure logic in `HeartRateCoachCore`; app wires the unlock screen + exercise-cue coaching. Decisions: Q1–Q9 all A.

## 1. Leg-exercise bank (§G, Q1/Q3/Q4)

### `LegExercise`
- `id`, `name`
- `mode: ExerciseMode` — `.bilateral` (30s / 15 reps) | `.unilateral` (32s / 8 reps per leg, switch cue)
- `impactedJoints: Set<LegJoint>` — joints the move stresses (for exclusion)

### `ExerciseMode`
`bilateral` → `durationSec 30`, `reps 15`, `perLeg false`
`unilateral` → `durationSec 32`, `reps 8`, `perLeg true`

### `LegJoint` (enum) — `knee | hip | ankle`
Mapping from P1b `JointIssue`: `knees→knee`, `hips→hip`, `ankles→ankle`; `back`/`none` → no leg exclusion.

### `LegExerciseBank` (static §G list of 8 — Q1=A)
**Tags are defaults, FLAGGED for collaborator confirmation** (safety-relevant):
| Exercise | Mode | Impacted joints |
|---|---|---|
| Squat jumps | bilateral | knee, ankle |
| Jumping lunges (alternating) | unilateral | knee, hip |
| Lateral bounds | bilateral | knee, ankle, hip |
| Step-up jumps | unilateral | knee, hip |
| Skater jumps | unilateral | knee, ankle |
| Jump rope (or phantom) | bilateral | ankle |
| Broad jumps | bilateral | knee, ankle |
| Split squat jumps | unilateral | knee, hip |

> Flag: spec line 59 says "20+"; §G lists 8. Using 8; expansion = pure data later (Q1).

## 2. Level Up unlock (§E, Q5)

### `LevelUpUnlock` (stored on profile)
- `injuredJoints: Set<LegJoint>` — from the §E injury question, **pre-filled from P1b `jointIssues`**, user-confirmed
- `comfortableWithBodyweight: Bool`
- `approvedExerciseIDs: Set<String>?` — when not comfortable (Q2), the user's hand-picked subset; nil = all eligible
- `unlockedAt: Date`

Persisted under `v2profile` (new optional section; back-compat nil).

## 3. Exercise selection + exclusion (Q2/Q4)

### `ExerciseSelector` (pure)
- `eligible(bank:unlock:) -> [LegExercise]` — drop any exercise whose `impactedJoints` intersect `injuredJoints` (BR-4-6); if `approvedExerciseIDs` set, intersect with it.
- `sequence(eligible:count:seed:) -> [LegExercise]` — seeded shuffle, draw **without replacement**, reshuffle on exhaustion (Q2=A); returns `count` picks (6 for Continuous, 10 for HIIT).

## 4. Protocol model additions (Q6)

### `PhaseKind.exercise` (NEW case)
Not HR-scored (excluded from the scoring denominator, like rest/cooldown). An exercise phase carries its assigned move + rep target.

### `FoundationPhase` gains `exercise: LegExercise?`
nil for all non-exercise phases; set on `.exercise` phases. (Keeps one phase type across stages.)

## 5. Level Up protocols (§2.1 / §2.2, Q6/Q7)

### `LevelUpProtocolBuilder` (pure) — distinct from `FoundationProtocolBuilder`
**Continuous (§2.1):** 7 blocks × 5:00, same %HRR table as Foundation. Blocks 1–6 internal timeline:
`block` run 0:00–3:50 → `exercise` 3:50–4:20/4:22 → `rest`(walk) → 5:00. Block 7 = pure `block` run (no exercise). Then buffer → transition gate → cooldown (reused from P2).
**HIIT (§2.2):** `warmup` 0:00–3:00 → `exercise` block 3:00–5:00 → **10 × round** where each round = `work` run 1:00 → `exercise` (20 reps) → `rest`(walk) to 3:00. Then transition → cooldown (no buffer). Per-round %HRR per §2.2 table.
Scored phases: `warmup` + `block`/`work` run portions only.

## 6. Exercise coaching (Q8)

### `ExerciseCue` / rep-count
During an `.exercise` phase the session driver emits (timeline-driven, deterministic):
- intro/visualization line (exercise name)
- **synced rep count**: paces `reps` over `durationSec`; unilateral → count 8, "switch legs", count 8
- "slow walk" cue after reps; "next phase" cue near walk end
`CoachingEngineV2` continues to drive the run (`block`/`work`/`warmup`) phases unchanged.

## 7. Stage advancement (Q9)

- Foundation complete (60) → present `LevelUpUnlock` flow → on completion:
  `program.currentStage = .levelUp`, add `StageProgress(.levelUp, 0)`, store `LevelUpUnlock`.
- `ProgressionEngine` (P3) is **stage-agnostic** — it already assigns from `currentProgress` (now Level Up's counter) and resolves the §B track from classification (carried over unchanged). No engine change.
- The session manager selects `LevelUpProtocolBuilder` when `currentStage == .levelUp`, else `FoundationProtocolBuilder`.

## 8. Reuse / out of scope
Reuse: P2 coaching/cooldown/scoring/session engine, P3 progression/relapse/minimum, P1b `jointIssues`. Out: Shape (P5), milestones/reminders/export/PDF (P6), Maintain.
