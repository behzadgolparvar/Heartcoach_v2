# Phase 3 — Business Logic Model (Progression & Assignment)

How the entities + rules compose. Pure core; app wires Home + the minimum walk.

## Pure core components

### `ProgressionTables`
Static §B data: `[ProgressionTrack: [MentalityLean: [SessionRatio]]]` (3 sub-phases each) + the Routine/Cardio special case. No I/O. PBT: every cell matches the spec table.

### `ProgressionEngine` (pure)
```
assign(profile) -> SessionAssignment
  track   = resolveTrack(profile.resolvedExperience, profile.goals)      // BR-3-1
  n       = profile.program.currentProgress.sessionsCompleted
  sub     = min(2, n / 20)                                               // BR-3-2
  if n >= 60: return SessionAssignment(stageComplete, subPhase 2 ratios) // BR-3-11
  type    = assignType(track, lean, n)                                   // BR-3-4
  return SessionAssignment(type, number: n+1, sub, ratio)

advance(program, session) -> ProgramState                                // BR-3-5/6
  guard session counts (scored continuous/hiit, ≥20min)
  sessionsCompleted = min(60, +1); lastCountedSessionDate = session.date

applyRelapse(program, asOf: now) -> (ProgramState, RelapseOutcome)       // BR-3-7/8
  band = gapBand(now - lastCountedSessionDate)
  apply push-back / reset (plain subtraction, Q5=B); stamp lastCountedSessionDate = now
```
`assignType` expands the ratio cycle (HIIT front-loaded) and indexes by `n % 20`, or applies the 1-in-4 Routine/Cardio rule. Deterministic → fully testable.

## Session flow (app layer)

```
App open / Home appears:
  (program, outcome) = ProgressionEngine.applyRelapse(program, now)      // once per gap
  if outcome.band != none: show positive re-entry message, persist program
  assignment = ProgressionEngine.assign(profile)
  Home shows "Today: <type> · Session N of 60"  [Start]  [Choose different]
        │                                            │
   Start (assigned)                          Choose different (override, Q9)
        └──────────────┬─────────────────────────────┘
                       ▼
     Phase 2 FoundationSessionManager runs the chosen type
                       ▼
     on completion → ProgressionEngine.advance(program, session)         // BR-3-5/6
                     persist program (sessionsCompleted, lastCountedSessionDate)
                     if sessionsCompleted == 60 → Foundation-complete state (Q8)

Home also: "Not feeling it? Do your 15-min minimum" → MinimumWalk flow
     on completion → stamp lastCountedSessionDate; do NOT advance counter  // BR-3-9
```

### Minimum walk flow (lightweight, separate from the session engine)
A timed 8-fast/7-slow walk with basic voice/timer cues; no HR coaching, no scoring. Writes a `minimum_walk`-flagged record, resets the relapse clock, leaves progression untouched.

## Data additions (persisted under `v2profile.program`)
- `ProgramState.lastCountedSessionDate: Date?` (Q6)
- (sessions already carry `sessionFlag`; add `"minimum_walk"` as a value)

## Integration with Phase 2
- Assignment chooses the `WorkoutType`; the existing `FoundationSessionManager` runs it unchanged.
- `advance` consumes the `Session` that P2 produces (uses `sessionFlag`, training-duration, `cooldownSkipped`).
- The Phase 2 manual picker becomes the Q9 override path.

## Testing focus (PBT partial)
- `resolveTrack` over experience × goal combinations (incl. multi-goal, Q2).
- `assignType`: ratio-cycle expansion + indexing across all tracks/leans/sub-phases; Routine/Cardio 1-in-4.
- `advance`: counts only qualifying sessions; clamps at 60; stamps date.
- `applyRelapse` (Q5=B): each §C band; plain subtraction crossing sub-phase boundaries; >1mo → 0; once-per-gap (re-apply is a no-op after stamping).
- Minimum walk: resets clock, never advances counter.

## Out of scope (later phases)
Level Up advance + exercises (P4), Shape (P5), reminders/push nudge + export + client PDF (P6), elevated-HR `walk_fallback` (§J, deferred from P2). Maintain out of scope.
