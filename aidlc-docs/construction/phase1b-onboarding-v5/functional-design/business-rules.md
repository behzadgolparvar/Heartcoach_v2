# Phase 1b — Business Rules (Onboarding v5 deltas)

IDs continue the `BR-1b-*` namespace for this phase. All rules are pure/deterministic and PBT-targetable unless noted.

## BR-1b-1 — Q1 history → tier mapping
`TrainingHistory.mappedTier`:
- `neverTrained` → `.beginner`
- `stoppedOverYear` → `.beginner`
- `recentReturnOrUnderYear` → `.intermediate`
- `overYearConsistent` → `.advanced`
Total function; every case mapped.

## BR-1b-2 — Experience resolution matrix (spec §A)
Input: `q1Tier = q1TrainingHistory.mappedTier`, `q2 = q2SelfSelect`. Output: `(resolved, mismatch)`.

| q1Tier | q2 | resolved | mismatch |
|---|---|---|---|
| beginner | advanced | intermediate | true |
| advanced | beginner | intermediate | true |
| any other combination | — | **q1Tier** | false |

So the ONLY cases that override Q1 are the two "extreme disagreement" pairs; every other disagreement (e.g. beginner/intermediate, intermediate/advanced) → **Q1 wins**, mismatch=false. Exhaustively testable over all 3×3 = 9 (q1Tier, q2) pairs.

## BR-1b-3 — Ozempic/GLP-1 override (spec §A)
If `healthHistory.onAntiObesityTherapy == true` → **resolved = `.beginner`**, overriding BR-1b-2 entirely. `mismatch` from BR-1b-2 is still computed and stored (research), but does not change the forced `.beginner`.
- Q1 and Q2 are **always asked and stored** regardless of Ozempic (research data).
- `resolvedExperience = onAntiObesityTherapy ? .beginner : BR-1b-2.resolved`.

## BR-1b-4 — Ozempic edit transitions (spec §A)
When the user edits the Ozempic flag post-onboarding:
- **No → Yes:** re-apply override (resolved → `.beginner`); UI shows informational popup (copy below). Does NOT reset `program` / session counters.
- **Yes → No:** re-run BR-1b-2 from stored Q1/Q2 (resolved reverts to the matrix result). Does NOT reset `program`.
- Classification change never reclassifies the training **stage** or resets progress (BR-1b-6).

Popup copy (verbatim from spec §A):
> "Research shows that combining exercise with GLP-1 medications like Ozempic is linked to greater fat loss and better weight-loss maintenance after stopping the medication." → confirm → "Your training will start at a Beginner level to build a strong, sustainable foundation alongside your medication."

## BR-1b-5 — Write-through of resolved value (Q2=A)
`fitnessExperience` is persisted as the resolved value, recomputed by `ExperienceResolver` whenever Q1, Q2, or the Ozempic flag changes (onboarding save + any Settings edit). Runtime consumers read the stored `fitnessExperience`; they never need the resolver. Invariant: `fitnessExperience == ExperienceResolver.resolve(q1, q2, ozempic)` at all persisted states.

## BR-1b-6 — Classification carries forward across stages (spec §A)
Experience is resolved once and **never reclassified between training stages**. Advancing Foundation→Level Up→Shape changes `currentStage` only; Q1/Q2/resolved are untouched.

## BR-1b-7 — New-user program init (Q7=A)
On onboarding completion, every user — regardless of resolved tier — starts at:
`currentStage = .foundation`, `stageProgress[.foundation] = StageProgress(stage: .foundation, sessionsCompleted: 0)`.
Classification affects ratio tables (P3), not the starting stage.

## BR-1b-8 — Sub-phase derivation (Q6=A)
`StageProgress.subPhase = min(2, sessionsCompleted / 20)` → 0 (sessions 0–19), 1 (20–39), 2 (40–59); `isStageComplete` at ≥60. Pure; testable over 0…60.

## BR-1b-9 — v5-completeness gate / migration (Q8=B)
A profile is **v5-complete** iff it decodes with non-nil `q1TrainingHistory`, `q2SelfSelect`, and `program.currentStage`. Any profile missing one (all pre-v5 Phase-1 profiles) is **not** v5-complete → routing sends the user to **full re-onboarding** (no tolerant/partial migration). `v2Completed` alone is insufficient; routing now requires v5-complete.
- Consequence: existing testers re-onboard once. Acceptable (few testers; avoids half-populated profiles).

## BR-1b-10 — Security (unchanged, still blocking)
- Q1/Q2/resolved/mismatch, Ozempic flag, and all health history are PII/health data: **never** written to console/analytics logs (SECURITY-03).
- Firestore own-data rules + consent gating from Phase 1 remain in force; new fields live under the same `users/{uid}.v2profile` document.

## Forward dependency (not implemented in P1b)
- **P4 (Level Up):** will read `healthHistory.jointIssues` to exclude leg exercises. P1b guarantees the data is captured/stored; no exclusion logic here.
- **P5 (Shape):** `dailyOptionSelection`, `muscleGroupPriority`, `MuscleGroup` are defined as the data contract only; unused until P5.
