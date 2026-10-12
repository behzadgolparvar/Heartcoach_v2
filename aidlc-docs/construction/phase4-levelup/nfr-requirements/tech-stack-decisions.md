# Phase 4 — Tech Stack Decisions (Level Up)

**No new technology decisions.** Reuses the fixed stack.

| Concern | Decision | Status |
|---|---|---|
| Leg bank / selection / Level Up protocols | `HeartRateCoachCore` (pure) | Reused package, new types |
| Protocol model | P2 `FoundationProtocol`/`FoundationPhase` + new `PhaseKind.exercise` | Reused/extended |
| Run coaching | P2 `CoachingEngineV2` | Reused unchanged (run phases) |
| Exercise cues + rep count | New cue layer in the session driver | App, reuses VoiceFeedback |
| Cooldown / buffer / transition | P2 (§F) | Reused |
| Progression / relapse / minimum | P3 `ProgressionEngine` | Reused unchanged (stage-agnostic) |
| Seeded RNG | P2 `SeededGenerator` | Reused (exercise selection) |
| Unlock screen | New SwiftUI view + profile section | App |
| Persistence | Firestore `v2profile` (+ `LevelUpUnlock`) | Reused |
| Testing / project gen | app test target + PBT; xcodegen | Reused |

## Placement
- `LegExercise`/`LegExerciseBank`/`LegJoint`/`ExerciseMode`, `LevelUpUnlock`, `ExerciseSelector`, `LevelUpProtocolBuilder`, `PhaseKind.exercise` → `HeartRateCoachCore`.
- Exercise-cue/rep-count layer + builder selection → app `Workout/` (extend `FoundationSessionManager`).
- Level Up unlock screen → app `Views/`.

No infrastructure changes → Infrastructure Design **SKIPPED**.
