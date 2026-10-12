# Phase 5 — Code Summary (Shape)

**Status:** complete. Core + iOS app build; full suite green (127 tests). SECURITY-03 grep clean. Device verification → Build & Test.

## Pure core (`HeartRateCoachCore`)
- `Models/WeightExercise.swift` + `Models/WeightExerciseBank.swift` — §G 5 banks × 6 (flagged); legs empty (Legs rule)
- `Models/ShapeSessionChoice.swift` — Option A/B + ranked priority/secondary + `isValid` (exactly-2)
- `Models/ShapeUnlock.swift` — equipment pref / focus areas / Level-Up-pain ack; added to `UserProfileV2` (tolerant Codable)
- `Models/FoundationProtocol.swift` — `FoundationPhase.muscle: MuscleGroup?`
- `Engine/ShapeExercisePlanner.swift` — `MuscleRole`, `ShapeAlternation` (4-2 / 6-5), `PlannedExercise`, planner (Legs rule: legs→plyo 20 via `ExerciseSelector`/injury-excluded; else weight 30; seeded)
- `Engine/ShapeProtocolBuilder.swift` — Continuous §3.1 (Block 1 = 6:00; 2–6 = 5:00; Block 7 pure run) + HIIT §3.2 (warm-up + Exercise Phase 0 + 10 rounds, 11 exercise phases, +10s overage)

## Tests (app target; PBT partial)
- `ShapeTests` (14) — bank counts (6/muscle, legs empty); 4-2 & 6-5 alternation; planner role→muscle + Legs rule rep counts + Option A all-legs + injury exclusion + seeded determinism; choice validation; Continuous + HIIT timelines & scored durations; `ShapeUnlock` Codable

## App integration
- `FoundationSessionManager` — `shapeHIITCadence` (2 checks at 15s/40s for Shape-HIIT runs); exercise-cue layer generalized to weight phases (announce "<name> — 30 reps") and plyometric (20 reps + switch-legs)
- `WorkoutViewModel` — `shapeChoice`; `start` builds the Shape protocol (planner → builder) when `stage == .shape`; passes `shapeHIITCadence`
- `HomeViewModel.completeShapeUnlock` — store `ShapeUnlock` + advance `currentStage = .shape`
- `HomeView` — "Unlock Shape" on the Level-Up-complete state; Shape Start routes to `ShapeChoiceView`
- `ShapeUnlockView` — §E equipment / pain ack / focus areas
- `ShapeChoiceView` — per-session Option A/B + rank-2-muscles picker (defaults from unlock) → starts the assigned type

## Security / compliance
- SECURITY-03: no muscle/selection/assignment values logged (new code has zero logging).
- SECURITY-01 / own-data / consent inherited; `ShapeUnlock` in `v2profile`. 02/04 N/A.
- PBT (partial): planner, builder, banks, serialization covered.

## Deferred / flagged (honest)
- Inherits the P4 deferrals (literal per-rep synced voice count; weights pace announces reps but doesn't voice-count each rep) → Build & Test.
- **Shape-HIIT 15s/40s offsets** are a device-tuning default (secondsPerTick=25 used for escalation counting on those runs) → confirm on device.
- Exercise-phase internal 2:10 structure folded into `.exercise`(60s) + `.rest` walk; the 0:10 talk/breathing are cues, not separate phases (minor timing approximation).
- **Flagged for collaborator (safety):** weight banks (§G transcription + exercise↔muscle + "30 reps, light-to-moderate" load guidance).
- §J `walk_fallback` still deferred (Build & Test).

## Program status
All three **designed** training stages (Foundation, Level Up, Shape) are now built. Maintain = out of scope (undesigned). Shape completion shows "Maintain coming soon".
