# Phase 1b — Code Generation Plan (single source of truth)

**Unit:** Onboarding v5 deltas · **Type:** brownfield (extend shipped Phase 1) · **Branch:** new_design_Sep_2026
**Design source:** `construction/phase1b-onboarding-v5/{functional-design,nfr-requirements,nfr-design}/*`
**Decisions:** Q1–Q7 = A, Q8 = B. **Rule:** app must keep building and v1 workout flow must keep running at every checkpoint.

## Milestone
A user completing onboarding answers Q1 (training history) + Q2 (self-select) + Ozempic; the app resolves classification via the matrix/override, initializes Foundation/session-0 program state, and persists the v5 profile. Pre-v5 profiles route to re-onboarding. 1b adds no protocol/coaching behavior.

---

## Step 1 — Core enums & value types (`HeartRateCoachCore/Models`)  [x]
- [x] `TrainingHistory.swift` — 4 cases + `mappedTier: FitnessExperience` (BR-1b-1)
- [x] `TrainingStage.swift` — `foundation/levelUp/shape/maintain`, `Comparable`/ordered, `var next: TrainingStage?`
- [x] `StageProgress.swift` — `stage`, `sessionsCompleted`, derived `subPhase` (min(2, n/20)), `isStageComplete` (≥60)
- [x] `ProgramState.swift` — `currentStage`, `stageProgress: [TrainingStage: StageProgress]`, `static func newUser()` → Foundation/0 (BR-1b-7)
- [x] `ShapeOption.swift` (`plyometric/weights`), `MuscleGroup.swift` (chest/back/shoulders/arms/abs/legs) — placeholders for P5
- All `Codable, Sendable, Equatable, CaseIterable` where sensible

## Step 2 — Experience resolver (`HeartRateCoachCore/Engine`)  [x]
- [x] `ExperienceResolver.swift` — pure `static func resolve(q1:q2:onGLP1:) -> (resolved: FitnessExperience, mismatch: Bool)` implementing BR-1b-2 (matrix) + BR-1b-3 (Ozempic override); `mismatch` reflects matrix only
- [x] No Firebase/UI imports; no value-emitting logging (SECURITY-03)

## Step 3 — Extend `UserProfileV2` (`HeartRateCoachCore/Models`)  [x]
- [x] Add stored fields: `q1TrainingHistory: TrainingHistory?`, `q2SelfSelect: FitnessExperience?`, `classificationMismatch: Bool` (default false), `program: ProgramState?`, `dailyOptionSelection: ShapeOption?`, `muscleGroupPriority: [MuscleGroup]?`
  - *New v5 fields are optional-backed so pre-v5 docs decode without throwing (NFR reliability); onboarding always populates them.*
- [x] `fitnessExperience` stays, now = resolved value (write-through by callers)
- [x] Add `var isV5Complete: Bool` = `q1TrainingHistory != nil && q2SelfSelect != nil && program?.currentStage != nil`
- [x] Keep custom `init` back-compatible: new params default (`q1TrainingHistory: TrainingHistory? = nil`, …) so existing call sites compile; synthesized `Codable` with optionals = tolerant decode
- [x] Update `UserProfileV2.fixture` (tests) to a v5-complete profile

## Step 4 — Core tests (app test target; PBT partial)  [x]
- [x] `ExperienceResolverTests` — exhaustive over 4×3×2 = 24 combos: assert resolved + mismatch; explicit matrix rows (B,A)/(A,B)→Intermediate+mismatch; Ozempic forces Beginner but preserves mismatch
- [x] `StageProgressTests` — subPhase/isStageComplete over 0…60
- [x] `ProfileV5CodableTests` — v5 round-trip; a pre-v5 (Phase-1) JSON fixture decodes with `isV5Complete == false` and does not throw

## Step 5 — Persistence (`FirestoreService` + mock)  [x]
- [x] `saveProfileV2` encodes new fields into `v2profile` map
- [x] `loadProfileV2` tolerant of missing v5 fields (optionals → nil)
- [x] `MockFirebaseService` unaffected beyond the new fixture

## Step 6 — Onboarding view model (`OnboardingViewModel`)  [x]
- [x] Rework experience: draft `q1TrainingHistory`, `q2SelfSelect` (replace single `fitnessExperience` draft input)
- [x] `save()` pipeline: call `ExperienceResolver.resolve(q1,q2,onAntiObesityTherapy)` → set `fitnessExperience`, `classificationMismatch`; init `program = .newUser()`; set `v2Completed = true`
- [x] Ozempic selection during onboarding triggers popup copy (BR-1b-4)
- [x] `isValid(_:)` for experience section = Q1 and Q2 both chosen

## Step 7 — Onboarding UI (`Views/Onboarding`)  [x]
- [x] Experience section: Q1 (honesty-framing prompt, 4 history options) + Q2 (plain-language tier defs); **Q2 view must not show/observe Q1 or resolved** (spec §A independence)
- [x] Ozempic popup (informational modal, confirm-to-continue, fixed copy) wired to the health/Ozempic control
- [x] Reuse existing `SelectRow`/components

## Step 8 — Routing (`AuthViewModel`)  [x]
- [x] Route to `.main` only when `profile.isV5Complete`; else `.onboarding` (Q8=B full re-onboard); preserve `.loadError` retry for load *failures*
- [x] Update `AuthViewModelTests` to use a v5-complete fixture for the main path + a non-v5 fixture → onboarding

## Step 9 — Settings edits (`SettingsViewModel` + `SettingsView`)  [x]
- [x] Editing experience edits Q1/Q2 → re-run resolver → write-through `fitnessExperience`/`classificationMismatch`; do not touch `program` (BR-1b-6)
- [x] Ozempic toggle: No→Yes popup + re-resolve→Beginner; Yes→No re-resolve from Q1/Q2 (BR-1b-4); program untouched

## Step 10 — Consumers, build, verify  [x]
- [x] Update any remaining references to the old single-experience onboarding input (HomeViewModel unaffected — reads resolved `fitnessExperience`)
- [x] `xcodegen generate`; build iOS + core; run full test suite
- [x] **SECURITY-03 grep check:** zero logging/analytics call sites reference the new field names or Ozempic flag value
- [x] Code summary in `construction/phase1b-onboarding-v5/code/`

---

### Scope estimate
~10 steps, ~12–15 files (6 new core types + resolver, profile extension, persistence, 2 view models, onboarding UI, routing, tests). Lowest-risk of the phases — additive, reuses Phase 1 infra. Main risk: the `fitnessExperience`-input → Q1/Q2 swap rippling into onboarding VM/UI and tests (Steps 6–9), handled so the app builds at each step.

### Traceability
FR-1 (dual experience + Ozempic), FR-8 (stage/counter data), v5-requirements revision; BR-1b-1…10. Security: SECURITY-03 (no health data in logs), own-data/consent inherited. PBT: resolver (24 combos), subphase, Codable round-trip.
