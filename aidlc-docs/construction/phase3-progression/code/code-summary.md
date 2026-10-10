# Phase 3 — Code Summary (Progression & Assignment)

**Status:** complete. Core + iOS app build; full suite green (103 tests). SECURITY-03 grep clean. Device verification → Build & Test.

## Pure core (`HeartRateCoachCore`)
- `Models/SessionRatio.swift` — HIIT:Continuous + front-loaded `cycle` (Q1)
- `Models/ProgressionTrack.swift` — `resolve(experience:goals:)` (Q2 weight-loss-wins)
- `Engine/ProgressionTables.swift` — §B tables (Beginner-FWL / Intermediate / Advanced × lean × sub-phase); Routine/Cardio = nil ratio
- `Models/SessionAssignment.swift`, `Models/RelapseBand.swift` (+ `RelapseOutcome`)
- `Models/ProgramState.swift` — + `lastCountedSessionDate: Date?` (custom Codable updated, tolerant)
- `Engine/ProgressionEngine.swift` — `assign` (ratio-cycle / Routine-Cardio 1-in-4 / stage-complete clamp), `advance` (counts only scored ≥20-min continuous/hiit; clamp 60; stamp date), `applyRelapse` (Q5=B plain subtraction, >1mo→0, once-per-gap), `registerMinimumWalk`

## Tests (app target; PBT partial)
- `ProgressionTablesTests` (5) — every §B cell + cycle front-loading
- `ProgressionEngineTests` (14) — track resolution (Q2), assignment cycles across tracks/leans, sub-phase boundary, Routine/Cardio 1-in-4 vs pure, stage-complete, advance gating + clamp, relapse bands + cross-boundary subtraction + reset + once-per-gap + no-baseline, minimum walk

## App integration
- `WorkoutSummaryViewModel` — advances progression once at save time for a qualifying session (`advance`), persists updated `program`
- `HomeViewModel` — applies relapse on load (persists + positive message), computes `assignment`, `recordMinimumWalk`
- `HomeView` — "Today's session" card (type · N of 60 · sub-phase) + Foundation-complete state (Q8) + relapse banner + "15-min minimum" entry; Start uses assigned type
- `WorkoutPreStartView` — accepts `assignedType`, pre-selects it (Q9 default), picker remains the override
- `MinimumWalkViewModel` + `MinimumWalkView` — timed 8-fast/7-slow walk (voice/timer, no HR/scoring); on completion → `recordMinimumWalk` (resets relapse clock, no advance)

## Security / compliance
- SECURITY-03: no progression/date/assignment values logged (new code has zero logging).
- SECURITY-01 / own-data / consent inherited; new state in `v2profile.program`. 02/04 N/A.
- PBT (partial): tables, track resolution, assignment, advancement, relapse, minimum — all covered.

## Notes / deferred
- The minimum walk resets the relapse clock but (by design) does **not** persist a `minimum_walk` Session record in P3 — the functional effect (clock reset, no advance) is what matters; research-logging the walk can be added with P6's export work.
- §J `walk_fallback` (deferred from P2) shares this phase's non-counting/clock-reset plumbing — natural to wire during Build & Test.
- Advancement happens at summary **save**; a session the user never saves won't advance (consistent with "save your workout" being the commit action).
