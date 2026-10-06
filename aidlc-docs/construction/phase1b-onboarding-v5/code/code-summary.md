# Phase 1b — Code Summary (Onboarding v5 deltas)

**Status:** complete. Core package + iOS app build; full test suite green on iPhone 17 simulator. SECURITY-03 grep check clean.

## New core files (`HeartRateCoachCore`)
- `Models/TrainingHistory.swift` — Q1 enum (4 options) + `mappedTier` (BR-1b-1)
- `Models/TrainingStage.swift` — `foundation/levelUp/shape/maintain`, `Comparable`, `next`
- `Models/StageProgress.swift` — `sessionsCompleted`, derived `subPhase`, `isStageComplete` (BR-1b-8)
- `Models/ProgramState.swift` — `currentStage` + `stageProgress` map, `newUser()` (BR-1b-7), custom Codable (stable string-keyed JSON)
- `Models/ShapeSelections.swift` — `ShapeOption`, `MuscleGroup` placeholders (P5)
- `Engine/ExperienceResolver.swift` — pure matrix + Ozempic override (BR-1b-2/3)

## Modified core
- `Models/UserProfileV2.swift` — added `q1TrainingHistory?`, `q2SelfSelect?`, `classificationMismatch`, `program?`, `dailyOptionSelection?`, `muscleGroupPriority?`; `fitnessExperience` now the resolved alias; `isV5Complete`; custom tolerant `init(from:)` so pre-v5 docs decode without throwing (encode stays synthesized).

## Modified app
- `ViewModels/OnboardingViewModel.swift` — Q1/Q2 draft (replaced single experience input); Ozempic `didSet` → popup; `save()` resolves classification (write-through) + inits Foundation/0 program.
- `Views/Onboarding/OnboardingContainerView.swift` — Q1 (honesty prompt) + Q2 (independent) pickers; Ozempic informational alert.
- `ViewModels/AuthViewModel.swift` — routing gate now `isV5Complete` (pre-v5 → re-onboard, Q8=B).
- `ViewModels/SettingsViewModel.swift` — edits Q1/Q2 + Ozempic with re-resolve; `resolvedExperience` preview; program untouched (BR-1b-6); populate suppresses spurious popup.
- `Views/Settings/SettingsView.swift` — training-history + self-rating pickers, Ozempic toggle, resolved-level label, info alert.
- `Firebase/FirestoreService.swift` — unchanged logic; generic Codable carries the new fields.

## Tests (app target; core SwiftCheck target still excluded per Phase 1)
- `ExperienceResolverTests` — exhaustive 24-combo matrix + override + mismatch; extreme-disagreement + Q1-wins + Ozempic-preserves-mismatch + history mapping.
- `StageProgressTests` — subPhase over 0…60, boundaries, isStageComplete, newUser, stage ordering/next.
- `ProfileV5CodableTests` — v5 round-trip, multi-stage program round-trip, pre-v5 JSON decodes without throwing and `isV5Complete == false`.
- Updated `OnboardingViewModelTests` (Q1/Q2 + resolve + Ozempic + popup), `AuthViewModelTests` (pre-v5 → onboarding), `TestFixtures` (v5 fixture + `preV5Fixture`).

## Security / compliance
- SECURITY-03: no logging call site references classification/Ozempic/experience fields (grep clean); new core files contain no logging.
- SECURITY-01 / own-data / consent: inherited from Phase 1; new fields ride the existing `users/{uid}.v2profile` document. SECURITY-02/04 N/A.
- PBT (partial): resolver (24 combos), subphase (0–60), serialization round-trips — all present.

## Deferred (later phases)
Ratio/progression math (P3) · leg-exercise exclusion from `jointIssues` (P4) · Option A/B + muscle-group logic (P5) · Maintain protocols (out of scope).
