# Phase 4 — Code Summary (Level Up)

**Status:** complete. Core + iOS app build; full suite green (116 tests). SECURITY-03 grep clean. Device verification → Build & Test.

## Pure core (`HeartRateCoachCore`)
- `Models/LegExercise.swift` — `LegExercise`, `ExerciseMode` (bilateral 30s/15, unilateral 32s/8-per-leg), `LegJoint` + `JointIssue→LegJoint` mapping
- `Models/LegExerciseBank.swift` — §G bank of 8 with mode + joint tags (flagged defaults)
- `Models/LevelUpUnlock.swift` — injuredJoints/comfortable/approvedExerciseIDs/unlockedAt; added to `UserProfileV2` (tolerant Codable)
- `Models/FoundationProtocol.swift` — `PhaseKind.exercise` (not scored) + `FoundationPhase.exercise`/`.exerciseReps`
- `Engine/ExerciseSelector.swift` — `eligible` (joint exclusion + comfort subset) + `sequence` (seeded no-repeat, empty-pool safe)
- `Engine/LevelUpProtocolBuilder.swift` — Continuous (§2.1: Blocks 1–6 run 230s + exercise + walk; Block 7 pure 300s run) + HIIT (§2.2: warm-up 180s + exercise block 120s + 10×(60s run / exercise 20reps / 60s walk))

## Tests (app target; PBT partial)
- `LevelUpTests` (13) — joint mapping; exclusion per joint + comfort subset + nil-unlock; seeded no-repeat sequence + reshuffle + empty-pool + determinism; Continuous timeline (6 exercises, Block 7 pure run, scored duration); HIIT structure (10 rounds, 11 exercises, 20 reps); mode timing; `LevelUpUnlock` Codable round-trip

## App integration
- `FoundationSessionManager` — `protocolOverride` (Level Up passes a prebuilt protocol); exercise-cue layer on `.exercise` phases (intro + rep target + "switch legs" for unilateral); run phases keep `CoachingEngineV2`; `mapPhaseType(.exercise) → .exercise`
- `WorkoutViewModel` — `stage`/`levelUpUnlock` context; `start` builds the Level Up protocol (eligible → seeded sequence → builder) when `stage == .levelUp`
- `AppContainer.makeWorkoutViewModel` / `HomeView` — pass stage + unlock from the profile
- `HomeViewModel` — `prefilledInjuredJoints` (from onboarding `jointIssues`), `completeLevelUpUnlock` (store unlock + advance `currentStage=.levelUp`, fresh counter)
- `LevelUpUnlockView` — §E injury (pre-filled) + comfort subset + caution; "Unlock Level Up" on the Foundation-complete state

## Security / compliance
- SECURITY-03: no injury/joint/exercise/assignment values logged (new code has zero logging).
- SECURITY-01 / own-data / consent inherited; `LevelUpUnlock` in `v2profile`. 02/04 N/A.
- PBT (partial): selector, builder, mapping, serialization covered.

## Deferred / flagged (honest)
- **Literal per-rep synced voice count** not implemented — the exercise cue announces the exercise + rep target and a mid-phase "switch legs", but does not voice-count each rep (needs a sub-second timer; → Build & Test on device).
- **HIIT unilateral handling simplified** — HIIT exercises pace 20 reps as a total (no per-leg switch), since §2.2 says "20 reps" without a per-leg split; confirm with collaborator.
- **5s tick vs 32s unilateral phase** — minor (~3s) timing drift from tick granularity; verify on device.
- **Flagged for collaborator (safety):** leg-bank size (8 vs "20+") and the per-exercise mode/joint tags.
- §J `walk_fallback` still deferred (Build & Test).
