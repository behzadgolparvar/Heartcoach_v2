# Phase 4 — Business Rules (Level Up)

`BR-4-*` namespace. Pure/deterministic and PBT-targetable unless noted.

## Exercise bank + metadata
- **BR-4-1 (bank, Q1):** the leg bank is the §G list of 8; expansion is data-only. Tags (mode, joints) are defaults flagged for collaborator confirmation.
- **BR-4-2 (mode timing, Q3):** `.bilateral` → 30s / 15 reps; `.unilateral` → 32s / 8 reps per leg (16 total) with a mid-phase "switch legs" cue.

## Selection + exclusion
- **BR-4-3 (eligibility, Q4):** an exercise is eligible iff `impactedJoints ∩ injuredJoints == ∅`. If `approvedExerciseIDs != nil` (user not comfortable, Q2), further restrict to that set.
- **BR-4-4 (selection, Q2):** per session, draw from the eligible pool using a seeded shuffle **without replacement**; reshuffle only when the pool is exhausted. Continuous draws 6 (Blocks 1–6), HIIT draws 10 (post-warmup block + rounds... see BR-4-8).
- **BR-4-5 (empty pool safeguard):** if exclusions empty the pool, fall back to the single lowest-impact eligible-by-comfort exercise or, if none, omit exercise phases (run-only) and surface a caution — never crash or assign an excluded move.
- **BR-4-6 (injury caution):** when `injuredJoints` non-empty, show the §E caution copy once at unlock: "Since you mentioned a recent injury, we've adjusted your exercises. If you feel pain during any movement, stop and consult a doctor before continuing."

## Unlock (§E, Q5)
- **BR-4-7 (unlock flow):** on Foundation completion, present the §E unlock: injury question **pre-filled from P1b `jointIssues`** (mapped via `LegJoint`), user confirms/edits; comfort question; if not comfortable, user pre-selects `approvedExerciseIDs`. Store `LevelUpUnlock`.

## Protocol construction (§2.1/§2.2, Q6/Q7)
- **BR-4-8 (Continuous, §2.1):** 7×5:00, Foundation %HRR table. Blocks 1–6: `block` run (0:00–3:50) + `exercise` (bilateral 30s → ends 4:20 / unilateral 32s → ends 4:22) + `rest` walk to 5:00. Block 7: pure `block` run, no exercise. 6 exercises/session.
- **BR-4-9 (HIIT, §2.2):** `warmup` 3:00 + `exercise` block (2:00) + 10×(`work` run 1:00 → `exercise` 20 reps → `rest` walk to 3:00). Per-round %HRR per the §2.2 table. 11 exercises total (1 block + 10 rounds) → selector draws 11 (reshuffles past 8).
- **BR-4-10 (exercise phase not scored):** `.exercise` phases are excluded from the scoring numerator/denominator (reuses P2 BR-2-12). Scored = `warmup` + run `block`/`work` only.
- **BR-4-11 (cooldown/buffer reuse):** §F cooldown + Continuous buffer + transition gate are appended identically to Foundation (P2 BR-2-17/18/19).

## Coaching (Q8)
- **BR-4-12 (exercise cues):** during `.exercise`, emit intro (exercise name) at phase start, a synced rep count over the phase duration (BR-4-2; unilateral inserts "switch legs" at the halfway rep), a "slow walk" cue at phase end, and a "next phase" cue near the following walk's end. Deterministic (timeline-driven), no RNG.
- **BR-4-13 (run coaching unchanged):** `CoachingEngineV2` drives `warmup`/`block`/`work` run phases exactly as in Foundation (priority ladder, severity, escalation, no-3×-repeat). Exercise and run coaching never overlap (disjoint phases).

## Progression / advancement (Q9)
- **BR-4-14 (stage-agnostic progression):** Level Up reuses P3 `ProgressionEngine` unchanged — assignment/advance/relapse/minimum operate on `currentProgress` (now Level Up's 60-session counter). Classification carries over unchanged (BR-1b-6).
- **BR-4-15 (advance):** on Foundation `sessionsCompleted == 60` + completed unlock → `currentStage = .levelUp`, `stageProgress[.levelUp] = StageProgress(.levelUp, 0)`. Builder selection keys on `currentStage`.
- **BR-4-16 (builder selection):** session manager uses `LevelUpProtocolBuilder` iff `currentStage == .levelUp`, else `FoundationProtocolBuilder`.

## Security (inherited, blocking)
- **BR-4-17:** injury/joint data, exercise selections, and assignments are health/PII — never console/analytics-logged (SECURITY-03). `LevelUpUnlock` persists under the existing own-data `v2profile` doc; no new auth surface.
