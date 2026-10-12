# Phase 4 — Business Logic Model (Level Up)

How the entities + rules compose. Pure core; app wires the unlock screen and exercise cues.

## Pure core components

### `LegExerciseBank`
Static §G list of 8 with mode + impacted-joint tags (BR-4-1/2). Data only.

### `ExerciseSelector` (pure)
```
eligible(bank, unlock):                                  // BR-4-3
  bank.filter { $0.impactedJoints.isDisjoint(with: unlock.injuredJoints) }
      .filter { unlock.approvedExerciseIDs?.contains($0.id) ?? true }

sequence(eligible, count, seed):                          // BR-4-4
  seeded shuffle; draw without replacement; reshuffle on exhaustion → [count]
  (empty pool → BR-4-5 safeguard)
```

### `LevelUpProtocolBuilder` (pure)
Builds a `FoundationProtocol` (reusing the P2 model + new `.exercise` phase) per BR-4-8/9, given the per-phase assigned exercises from `ExerciseSelector`. Continuous = 6 exercise phases; HIIT = 11. Appends buffer/transition/cooldown identically to Foundation.

### `ProgressionEngine` (P3, reused unchanged)
Assignment/advance/relapse operate on the current stage's counter (BR-4-14). No change.

## Session flow (app layer)

```
Foundation sessionsCompleted == 60:
   Home shows Level Up unlock (was "coming soon"):
     injury Q (pre-filled from P1b jointIssues) + comfort Q (+ subset pick)   // BR-4-7
     → store LevelUpUnlock; currentStage = .levelUp; StageProgress(.levelUp,0) // BR-4-15
     → show injury caution if any injured joints                              // BR-4-6

Home (currentStage == .levelUp):
   assignment = ProgressionEngine.assign(profile)        // continuous/hiit (P3)
   Start → build session:
     eligible = ExerciseSelector.eligible(bank, unlock)
     picks    = ExerciseSelector.sequence(eligible, count: type==hiit ? 11 : 6, seed)
     protocol = LevelUpProtocolBuilder.build(type, picks)   // BR-4-8/9, BR-4-16
     FoundationSessionManager runs it:
        run phases      → CoachingEngineV2 (HR coaching)     // BR-4-13
        exercise phases → ExerciseCue + synced rep count     // BR-4-12
        buffer/transition/cooldown → as Foundation           // BR-4-11
        scoring          → run phases only                    // BR-4-10
   on completion → ProgressionEngine.advance (Level Up counter)  // P3, BR-4-14
```

## Session-manager extension
`FoundationSessionManager` gains:
- builder selection by `currentStage` (BR-4-16) — or a thin `LevelUpSessionManager` reusing the same tick loop with the exercise-cue layer added.
- an **exercise-cue layer**: when the current phase is `.exercise`, drive intro + synced rep count (+ "switch legs" for unilateral) + walk/next cues, instead of the HR tick. Run phases still call `CoachingEngineV2`.

## Data additions (persisted under `v2profile`)
- `LevelUpUnlock` section (injuredJoints, comfortableWithBodyweight, approvedExerciseIDs?, unlockedAt)
- `PhaseKind.exercise` + `FoundationPhase.exercise: LegExercise?` (in-memory protocol; not persisted — rebuilt per session)

## Testing focus (PBT partial)
- `ExerciseSelector.eligible`: exclusion by injured joint (each joint); comfort-subset intersection; empty-pool safeguard.
- `ExerciseSelector.sequence`: no-repeat-until-exhausted under a fixed seed; correct counts (6 / 11).
- `LevelUpProtocolBuilder`: Continuous block internal timeline (run/exercise/walk; Block 7 pure run); HIIT §2.2 structure (warmup + block + 10×3:00); %HRR per phase; scored-phase set; exercise mode → duration/reps.
- Mapping P1b `jointIssues` → `LegJoint`.
- Stage advance Foundation(60)→Level Up resets counter; classification unchanged.

## Out of scope
Shape (P5), milestones/reminders/export/PDF (P6), Maintain. §J `walk_fallback` still deferred (Build & Test).
