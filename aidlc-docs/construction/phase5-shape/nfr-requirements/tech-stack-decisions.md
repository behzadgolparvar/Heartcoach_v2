# Phase 5 — Tech Stack Decisions (Shape)

**No new technology decisions.** Reuses the fixed stack.

| Concern | Decision | Status |
|---|---|---|
| Weight banks / planner / Shape protocols | `HeartRateCoachCore` (pure) | Reused package, new types |
| Protocol model | P2 `FoundationProtocol`/`FoundationPhase` + `.exercise` (+ `muscle`) | Reused/extended |
| Leg content / selection / injury exclusion | P4 `LegExerciseBank` + `ExerciseSelector` + `LevelUpUnlock` | Reused |
| Run coaching | P2 `CoachingEngineV2` | Reused (Shape-HIIT differs only in tick cadence) |
| Exercise cues | P4 cue layer | Reused/extended (weights announce 30 reps) |
| Cooldown / scoring | P2 | Reused |
| Progression / relapse / minimum | P3 `ProgressionEngine` | Reused unchanged |
| Seeded RNG | P2 `SeededGenerator` | Reused |
| Unlock + per-session picker | New SwiftUI views + profile section | App |
| Persistence | Firestore `v2profile` (+ `ShapeUnlock`) | Reused |
| Testing / project gen | app test target + PBT; xcodegen | Reused |

## Placement
- `WeightExercise`/`WeightExerciseBank`, `ShapeSessionChoice`, `ShapeAlternation`, `ShapeExercisePlanner`, `ShapeProtocolBuilder`, `ShapeUnlock`, `FoundationPhase.muscle` → `HeartRateCoachCore`.
- Builder selection + Shape-HIIT cadence + weight-exercise cue → app `Workout/` (extend `FoundationSessionManager`).
- Shape unlock screen + per-session Option A/B + muscle picker → app `Views/`.

No infrastructure changes → Infrastructure Design **SKIPPED**.
