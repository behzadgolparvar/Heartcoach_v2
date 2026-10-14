# Phase 1b — Domain Entities (Onboarding v5 deltas)

**Scope:** additive/edited entities in `HeartRateCoachCore` and `UserProfileV2`. Technology-agnostic. Decisions: Q1–Q7 = A, Q8 = B.

## 1. Experience classification

### `FitnessExperience` (existing — reused)
`beginner | intermediate | advanced`. No change.

### `TrainingHistory` (NEW enum — Q1 answer, Q3=A)
The authoritative Q1 input. Four user-facing options mapped to a tier:

| Case | User-facing label | Maps to |
|---|---|---|
| `neverTrained` | "I've never trained consistently" | Beginner |
| `stoppedOverYear` | "I trained before but stopped 1+ year ago" | Beginner |
| `recentReturnOrUnderYear` | "I'm returning after a break under a year, or have trained <1 yr consistently" | Intermediate |
| `overYearConsistent` | "I've trained consistently for 1+ years" | Advanced |

`var mappedTier: FitnessExperience` — pure mapping above. Carries honesty-framing prompt text in the UI layer (not the model).

### Dual-experience fields on `UserProfileV2` (Q1=A)
- `q1TrainingHistory: TrainingHistory` — authoritative source
- `q2SelfSelect: FitnessExperience` — self-selected tier, shown with plain-language defs, Q1 result hidden
- `fitnessExperience: FitnessExperience` — **kept as the stored alias of the resolved value** (back-compat; all existing consumers keep reading this field). Written through at onboarding/edit (Q2-resolution = A).
- `classificationMismatch: Bool` (Q4=A) — true when (Q1 tier, Q2) ∈ {(B,A),(A,B)}. Research field; never console-logged (SECURITY-03).

> `fitnessExperience` is no longer entered directly — it is always the output of the resolver (`ExperienceResolver`, see business-rules). Settings edits to experience edit Q1/Q2, then re-resolve.

## 2. Ozempic / GLP-1 (Q5=A)
Reuse `HealthHistory.onAntiObesityTherapy: Bool` as the GLP-1 flag that drives the override. No new field. The resolver reads it; "Yes" forces resolved = `.beginner`.

## 3. Training stage & progression (Q6=A, Q7=A)

### `TrainingStage` (NEW enum)
`foundation | levelUp | shape | maintain`. `maintain` is defined for completeness but out of scope this cycle (no protocols). Ordered; `var next: TrainingStage?`.

### `StageProgress` (NEW struct)
Per-stage progression record (P1b defines the contract; P3 drives it):
- `stage: TrainingStage`
- `sessionsCompleted: Int` (0…60)
- `var subPhase: Int` — derived `min(2, sessionsCompleted / 20)` → 0,1,2 (3 sub-phases of 20)
- `var isStageComplete: Bool` — `sessionsCompleted >= 60`

### `ProgramState` (NEW struct) — on `UserProfileV2`
- `currentStage: TrainingStage` (new users → `.foundation`, Q7=A)
- `stageProgress: [TrainingStage: StageProgress]` — map, preserves per-stage history (Q6=A). New users → `[.foundation: StageProgress(stage: .foundation, sessionsCompleted: 0)]`.

## 4. Shape-stage placeholders (Q6 context — filled in P5)
On `UserProfileV2` (optional, nil until Shape reached):
- `dailyOptionSelection: ShapeOption?` where `ShapeOption = plyometric | weights` (Option A/B)
- `muscleGroupPriority: [MuscleGroup]?` — ordered priority list (defined but unused until P5)

`MuscleGroup` (NEW enum, used only as data contract now): `chest | back | shoulders | arms | abs | legs`.

## 5. Health/joint history → "active" (data contract only)
`HealthHistory.jointIssues` / conditions remain as stored. P1b adds no exclusion logic; it only documents that P4 (Level Up) will read `jointIssues` to exclude leg exercises. No model change required — flagged in business-rules as a forward dependency.

## 6. Migration (Q8=B)
No tolerant decode. A profile missing any required v5 field (`q1TrainingHistory`, `q2SelfSelect`, `currentStage`) is treated as **not v5-complete** → routed to full re-onboarding. See business-rules BR-1b-7.

## Entity relationship summary
```
UserProfileV2
 ├─ q1TrainingHistory : TrainingHistory      (NEW, authoritative)
 ├─ q2SelfSelect      : FitnessExperience     (NEW)
 ├─ fitnessExperience : FitnessExperience     (EXISTING — now = resolved alias)
 ├─ classificationMismatch : Bool             (NEW, research)
 ├─ healthHistory.onAntiObesityTherapy : Bool (EXISTING — drives Ozempic override)
 ├─ program : ProgramState                    (NEW)
 │    ├─ currentStage : TrainingStage
 │    └─ stageProgress : [TrainingStage: StageProgress]
 ├─ dailyOptionSelection : ShapeOption?        (NEW placeholder, P5)
 └─ muscleGroupPriority  : [MuscleGroup]?       (NEW placeholder, P5)
```
