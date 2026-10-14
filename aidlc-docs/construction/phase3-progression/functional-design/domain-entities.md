# Phase 3 — Domain Entities (Progression & Assignment)

Technology-agnostic. Pure logic in `HeartRateCoachCore`; app wires Home + the minimum-walk flow. Decisions: Q1–Q4=A, Q5=B, Q6–Q9=A.

## 1. Ratio tables (§B)

### `SessionRatio`
HIIT : Continuous for a sub-phase.
- `hiit: Int`, `continuous: Int`
- `var cycle: [WorkoutType]` — expanded repeating pattern (Q1=A), HIIT front-loaded within the group: e.g. `1:2 → [hiit, continuous, continuous]`, `2:1 → [hiit, hiit, continuous]`, `1:4 → [hiit, cont, cont, cont, cont]`.

### `ProgressionTables` (static data, §B)
Keyed by track × mentality lean × sub-phase index (0–2). `MentalityLean` = `outcome | process | mixed` (from P1b).

**Beginner — Fast Weight Loss**
| Lean | SP1 | SP2 | SP3 |
|---|---|---|---|
| outcome | 1:2 | 1:1 | 2:1 |
| mixed | 1:3 | 1:2 | 1:1 |
| process | 1:4 | 1:3 | 1:2 |

**Intermediate**
| Lean | SP1 | SP2 | SP3 |
|---|---|---|---|
| outcome | 1:1 | 2:1 | 3:1 |
| mixed | 1:2 | 1:1 | 2:1 |
| process | 1:3 | 1:2 | 1:1 |

**Advanced**
| Lean | SP1 | SP2 | SP3 |
|---|---|---|---|
| outcome | 2:1 | 3:1 | 4:1 |
| mixed | 1:1 | 2:1 | 3:1 |
| process | 1:2 | 1:1 | 2:1 |

**Beginner — Routine/Cardio** (not a ratio, Q3=A): pure Continuous; `outcome` lean → HIIT every 4th session; `process`/`mixed` → pure Continuous.

### `ProgressionTrack` (enum)
Resolves which rule-set applies (Q2=A):
`beginnerFastWeightLoss | beginnerRoutineCardio | intermediate | advanced`
- Derived from `resolvedExperience` + `goals`: Beginner + `goals.contains(.fastWeightLoss)` → FWL; Beginner otherwise → RoutineCardio; Intermediate/Advanced → their track (goal-independent).

## 2. Assignment

### `SessionAssignment`
What the engine proposes for the next session.
- `type: WorkoutType` (continuous/hiit)
- `sessionNumber: Int` (1-based within the stage, = `sessionsCompleted + 1`)
- `subPhase: Int` (0–2)
- `ratio: SessionRatio?` (nil for routine/cardio pure-Continuous)
- `isStageComplete: Bool` (Q8 — true at 60)

### `ProgressionEngine` (pure)
- `assign(profile:) -> SessionAssignment` — resolve track → sub-phase → ratio → index into `ratio.cycle` by `sessionsCompleted % 20` (BR-3-2/3).
- `advance(program:after session:) -> ProgramState` — increments `sessionsCompleted` iff the session counts (BR-3-5), clamped at 60; stamps `lastCountedSessionDate`.
- `applyRelapse(program:asOf:) -> (ProgramState, RelapseOutcome)` — §C push-back (BR-3-7, Q5=B).

## 3. Relapse (§C, Q5=B)

### `RelapseBand` (enum)
`none | pushBack3 | pushBack5 | pushBack8 | resetToStart` from the gap:
≤1w none · 2w −3 · 3w −5 · 1mo −8 · >1mo reset to Sub-Phase 1 (session 0).

### `RelapseOutcome`
`band: RelapseBand`, `sessionsBefore: Int`, `sessionsAfter: Int` — for the positive-framing message.

### Data addition — `ProgramState.lastCountedSessionDate: Date?` (Q6=A)
Stamped whenever a session counts (BR-3-5) **or** the non-negotiable minimum runs (BR-3-9). Basis for the relapse gap.

## 4. Non-negotiable minimum (§I, Q7=A)

### `MinimumWalk`
A simple timed walk — not a FoundationProtocol session, not HR-coached, not scored.
- Structure: 8 min fast + 7 min slow (15 min), basic voice/timer cues.
- `sessionFlag = "minimum_walk"`.
- Effects: updates `lastCountedSessionDate` (resets relapse clock), **does not** increment `sessionsCompleted`.

## 5. Stage completion (§E / Q8=A)
At `sessionsCompleted == 60`: `isStageComplete = true`. P3 shows a "Foundation complete — Level Up coming soon" state and keeps assigning from **Sub-Phase 3** (clamped). The real advance to Level Up (set `currentStage = .levelUp`, fresh `StageProgress`, §E unlock questions) is P4.

## 6. Home integration (Q9=A)
Home shows "Today's session: <type> · Session N of 60" + Start (assigned path) and a secondary "Choose a different workout" override. An override of a Foundation type still counts (BR-3-6); the schedule is counter-indexed, so a deviation never corrupts future assignments.

## 7. Flags summary (counting vs relapse clock)
| Outcome | Counts toward 60? | Resets relapse clock? |
|---|---|---|
| Scored Continuous/HIIT (assigned or override) | yes | yes |
| `cooldownSkipped` session | yes | yes |
| `minimum_walk` (§I) | no | yes |
| `walk_fallback` (§J, deferred) | no | yes |
| <20-min discard (§J) | no | no |
