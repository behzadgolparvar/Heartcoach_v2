# Phase 4 — NFR Design (Level Up)

How the NFR requirements are realized. Concise; patterns + placements.

## 1. Purity / determinism
- `LegExerciseBank` is immutable static data (mode + joint tags). `ExerciseSelector` and `LevelUpProtocolBuilder` are pure functions over value inputs + an injected `seed` — reproducible selection and timelines for tests (no global RNG, no `Date()` inside).
- Exercise-cue rep count is a pure function of (exercise, elapsed-in-phase) → deterministic cue schedule; no HR dependency.

## 2. Safety patterns
- **Exclusion is enforced at the single source** — `ExerciseSelector.eligible` is the only place exercises enter a session; the builder consumes its output, so no excluded move can reach a phase (BR-4-3/5). Invariant (tested): for any `injuredJoints`, every selected exercise has `impactedJoints` disjoint from it.
- **Empty-pool degrades safely** — lowest-impact eligible, else run-only + caution; never crash, never assign excluded.
- Run-phase HR safety (HR>max emergency) and §J reuse P2 unchanged; `.exercise` phases are low-intensity and non-scored, safety still passively watching.

## 3. Reuse patterns (minimize new surface)
- `.exercise` is one new `PhaseKind` case + an optional `exercise` on `FoundationPhase`; the P2 phase sequencer, two-clock timing, segment-tagged `hr_stream`, scoring exclusions, and §F cooldown all work unchanged.
- Run phases keep calling `CoachingEngineV2`; only `.exercise` phases route to the new cue layer. The two are **disjoint by phase kind** — no branching inside the HR engine.
- Progression/relapse/minimum (P3) untouched — stage-agnostic; builder selection keys on `currentStage`.

## 4. Security (SECURITY-03)
- Bank, selector, builder, unlock, and cue layer contain **no logging**. Code-Gen gets the same grep-check over the new types (incl. `LevelUpUnlock`, injured joints, exercise names) → zero hits. `LevelUpUnlock` persists under the existing own-data doc (SECURITY-01); no new auth/network (02/04 N/A).

## 5. Testability
- Seed injected into selection → reproducible sequences.
- Pure builder → assert phase timelines (Continuous run/exercise/walk; Block 7 pure run; HIIT §2.2 10×3:00), %HRR per phase, scored-phase set, mode→duration/reps.
- Exclusion + empty-pool + `jointIssues→LegJoint` mapping tested exhaustively.

## 6. Usability
- Every exercise cue (intro, each rep tick, "switch legs", "slow walk", "next phase") carries display text; the in-session view renders the exercise name + rep progress regardless of mute. Injury caution is a one-time modal at unlock.

## 7. Component / placement map
| Concern | Component | Location |
|---|---|---|
| Bank + metadata | `LegExerciseBank`, `LegExercise`, `ExerciseMode`, `LegJoint` | `HeartRateCoachCore` |
| Selection/exclusion | `ExerciseSelector` | `HeartRateCoachCore` |
| Level Up timelines | `LevelUpProtocolBuilder` (+ `PhaseKind.exercise`) | `HeartRateCoachCore` |
| Unlock state | `LevelUpUnlock` (on profile) | `HeartRateCoachCore` |
| Exercise cues + rep count + builder selection | session-driver extension | app `Workout/` |
| Unlock screen + injury caution | views | app `Views/` |

## 8. Infrastructure Design — SKIPPED
No new infrastructure. Consistent with prior phases.
