# Phase 5 — Business Logic Model (Shape)

How the entities + rules compose. Pure core; app wires the per-session picker + unlock.

## Pure core components

### `WeightExerciseBank`
Static §G data, 6 per muscle. `exercises(for: MuscleGroup) -> [WeightExercise]`.

### `ShapeExercisePlanner` (pure)
Given a `ShapeSessionChoice` + the phase-role pattern + seed, produces the ordered list of exercises for the session's exercise phases (BR-5-4/5/6/7/8):
```
plan(choice, type, unlock, seed):
  roles = (type == .hiit) ? HIIT_6_5 : CONTINUOUS_4_2         // BR-5-6/7
  for each phase:
     muscle = (choice.option == .plyometric) ? .legs
              : (role == .priority ? choice.priority! : choice.secondary!)
     exercise = (muscle == .legs)
        ? ExerciseSelector.sequence(legBank eligible by unlock injuries, …)  // 20 reps
        : weighted pick from WeightExerciseBank[muscle]                       // 30 reps
```

### `ShapeProtocolBuilder` (pure)
Builds the §3.1/§3.2 `FoundationProtocol` using the planned exercises (BR-5-9/10): run/exercise/walk phases with the right durations + %HRR; reuses `PhaseKind.exercise`, buffer/transition/cooldown. Pure; testable.

### `ProgressionEngine` (P3, reused unchanged) — BR-5-18.

## Session flow (app layer)

```
Level Up sessionsCompleted == 60:
   Home shows Shape unlock (§E): equipment pref + Level-Up-pain ack + focus areas   // BR-5-14
   → store ShapeUnlock; currentStage = .shape; StageProgress(.shape,0)              // BR-5-15

Home (currentStage == .shape), Start:
   per-session choice screen: Option A or B (default from unlock)                    // BR-5-1
     if B: pick + rank exactly 2 muscles (pre-filled from focusAreas)                // BR-5-2
   assignment = ProgressionEngine.assign(profile)        // continuous/hiit (P3 ratio)
   exercises = ShapeExercisePlanner.plan(choice, type, unlock, seed)
   protocol  = ShapeProtocolBuilder.build(type, exercises, choice)                   // BR-5-9/10
   FoundationSessionManager runs it:
      run phases       → CoachingEngineV2; Shape-HIIT runs use 2-checks cadence       // BR-5-12
      exercise phases  → exercise-cue layer (reps by type: 20 plyo / 30 weight)       // BR-5-13
      cooldown/scoring → as before                                                    // BR-5-11
   on completion → ProgressionEngine.advance (Shape counter)                          // BR-5-18
   at 60 → "Shape complete — Maintain coming soon"                                    // BR-5-16
```

## Session-manager extension
- Builder selection by `currentStage` (BR-5-17) — `ShapeProtocolBuilder` for `.shape`.
- Shape-HIIT run cadence: the driver fires the coaching tick at ~15s/40s of a 50s `work` phase when the active protocol is Shape-HIIT (flagged on the session), instead of every 15s.
- Exercise cues reuse P4; weight phases announce "<name> — 30 reps".

## Data additions (persisted under `v2profile`)
- `ShapeUnlock` (equipmentPreference, focusAreas, acknowledgedLevelUpPain, unlockedAt)
- `ShapeSessionChoice` is per-session/in-memory (not persisted; last choice may be remembered for the default)
- `FoundationPhase.muscle: MuscleGroup?` (in-memory protocol)

## Testing focus (PBT partial)
- `ShapeExercisePlanner`: 4-2 / 6-5 role patterns exact; Option B role→muscle; Legs rule (legs→plyo 20 / other→weight 30); Option A all-legs; injury exclusion on leg phases; seeded determinism.
- `ShapeProtocolBuilder`: Continuous block timings (Block 1 = 6:00; 2–6 = 5:00; Block 7 pure run); HIIT §3.2 (warm-up + Phase 0 + 10 rounds = 11 exercise phases; +10s overage); %HRR per phase; scored-phase set.
- `WeightExerciseBank`: 6 per muscle; legs has none.
- Advancement Level Up(60)→Shape; Shape(60)→complete state.

## Out of scope
Milestones/reminders/export/PDF (P6), Maintain. §J `walk_fallback` + P4/P5 device refinements → Build & Test.
