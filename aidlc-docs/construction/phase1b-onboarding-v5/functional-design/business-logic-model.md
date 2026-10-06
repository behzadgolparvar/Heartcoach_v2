# Phase 1b — Business Logic Model (Onboarding v5 deltas)

How the entities (domain-entities.md) and rules (business-rules.md) compose into workflows. Technology-agnostic.

## Core pure component: `ExperienceResolver`
Single source of truth for classification. Pure, no I/O, fully PBT-targetable.

```
resolve(q1: TrainingHistory, q2: FitnessExperience, onGLP1: Bool)
    -> (resolved: FitnessExperience, mismatch: Bool)

  let q1Tier = q1.mappedTier                      // BR-1b-1
  let (matrixResolved, mismatch) = matrix(q1Tier, q2)   // BR-1b-2
  let resolved = onGLP1 ? .beginner : matrixResolved    // BR-1b-3
  return (resolved, mismatch)
```
- `mismatch` reflects the matrix only (independent of the Ozempic override), so research data captures the Q1/Q2 disagreement even when Ozempic forces Beginner.

## Workflow 1 — Onboarding (new user)
1. Consent → demographics → … (Phase 1 sections, unchanged) →
2. **Experience section (reworked):**
   a. Q1 training-history (honesty-framing prompt) → `q1TrainingHistory`
   b. Q2 self-select tier (plain-language defs; **Q1 result hidden**) → `q2SelfSelect`
3. Health section: Ozempic/GLP-1 question → `healthHistory.onAntiObesityTherapy`. If Yes → show popup (BR-1b-4 copy).
4. On save:
   - `(resolved, mismatch) = ExperienceResolver.resolve(q1, q2, onGLP1)` → write `fitnessExperience = resolved`, `classificationMismatch = mismatch` (BR-1b-2/3/5)
   - init program: `currentStage = .foundation`, `stageProgress = [.foundation: 0]` (BR-1b-7)
   - set `v2Completed = true` **and** the profile is now v5-complete (all three required fields present)
   - persist to `users/{uid}.v2profile`

## Workflow 2 — Edit experience (Settings)
1. User edits Q1 and/or Q2 → re-run `ExperienceResolver` → write-through `fitnessExperience`, `classificationMismatch` (BR-1b-5).
2. `currentStage` and `stageProgress` untouched (BR-1b-6).

## Workflow 3 — Edit Ozempic flag (Settings)
- **No→Yes:** set flag, show popup, re-resolve → `.beginner` (BR-1b-4). Program untouched.
- **Yes→No:** clear flag, re-resolve from stored Q1/Q2 (BR-1b-4). Program untouched.

## Workflow 4 — Routing / migration (BR-1b-9, Q8=B)
On auth success, load profile:
```
if profile == nil                      -> onboarding
else if !profile.isV5Complete          -> onboarding   (full re-onboard; pre-v5 testers)
else                                    -> main
preserve existing .loadError retry path on load failure
```
`isV5Complete = q1TrainingHistory != nil && q2SelfSelect != nil && program?.currentStage != nil`.

## Data flow summary
```
Q1 (TrainingHistory) ─┐
Q2 (FitnessExperience)─┼─> ExperienceResolver ─> fitnessExperience (stored, resolved)
Ozempic flag ─────────┘                       └─> classificationMismatch (stored, research)

onboarding complete ─> ProgramState(currentStage=.foundation, stageProgress[.foundation]=0)
```

## Persistence shape (additions to `v2profile`)
```
v2profile:
  ... (Phase 1 fields) ...
  q1TrainingHistory: <string>
  q2SelfSelect: <string>
  fitnessExperience: <string>          # now = resolved
  classificationMismatch: <bool>
  healthHistory: { ..., onAntiObesityTherapy: <bool> }   # existing
  program:
    currentStage: <string>
    stageProgress: { foundation: { stage, sessionsCompleted } , ... }
  dailyOptionSelection: <string?>      # placeholder (P5)
  muscleGroupPriority: [<string>]?     # placeholder (P5)
```

## Testing focus (PBT partial)
- `ExperienceResolver.resolve` — exhaustive over all (TrainingHistory ×4) × (FitnessExperience ×3) × (Ozempic bool) = 24 combos; assert matrix + override + mismatch flag.
- `StageProgress.subPhase` / `isStageComplete` — over 0…60.
- `UserProfileV2` Codable round-trip incl. all new fields + a pre-v5 fixture decoding as **not** v5-complete.

## Out of scope for P1b (carried forward)
- Ratio tables / progression math (P3), leg-exercise exclusion from jointIssues (P4), Option A/B + muscle-group logic (P5), Maintain stage protocols (deferred).
