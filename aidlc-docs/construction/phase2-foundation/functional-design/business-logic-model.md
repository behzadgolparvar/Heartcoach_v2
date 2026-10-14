# Phase 2 — Business Logic Model (Foundation Protocols + Coaching)

How the entities + rules compose into the runnable Foundation session. Technology-agnostic; pure core where possible.

## Pure core components

### `FoundationProtocolBuilder`
`build(type:profile:) -> WorkoutProtocol`. Produces the deterministic phase timeline (BR-2-1/2/3): computes each scored phase's `TargetRange.bpmRange` from the profile's HRR, appends buffer (Continuous only), the transition gate, and the 6 cooldown steps. No I/O. PBT: every profile → monotonic, spec-matching bpm ranges; phase durations sum to the spec totals.

### `CoachingEngineV2` (Q6=A — new, leaves v1 engine intact)
Pure function of (tick context) → `CoachingMessage?`.
```
tick(hr, sessionSec, phase, state) -> CoachingMessage?
  1. safety:       hr > maxHR            -> emergency (handled by caller; engine flags)
  2. endOfPhase:   last 10s of phase     -> transition/direction announce
  3. escalation:   offRun ≥ 30/60s       -> escalation phrase         (BR-2-7)
  4. offZone:      off > 0               -> pool[severity,direction]  (BR-2-6)
  5. inZone:       once-per-block earned -> confirmation              (BR-2-8)
  6. transition:   block/round start     -> "Block N", "N left"
  select phrase via seeded RNG, no-3x-repeat                           (BR-2-9)
  update state (recent phrases, offRun, inZone progress)
```
Rest phases short-circuit to instructional-only (BR-2-10). Deterministic given (HR trace, seed) → fully testable.

### `SessionScorer`
`score(records:protocol:) -> SessionScore`. Filters `hr_stream` to scored phases, counts in-range seconds per BR-2-12/13, maps to tier (BR-2-14), tallies per-zone seconds. Pure. PBT: all-in-range ⇒ 100/excellent; all-out ⇒ 0/needsWork; tier boundaries exact; rest/cooldown never affect the result.

### `BriefingPolicy`
`isMandatory(type:stage:history:) -> Bool` (BR-2-11) — pure over existing state.

## Session flow (app layer, drives the pure core)

```
pick workout (manual, Q7)              ──► FoundationProtocolBuilder.build
      │
briefing? (BriefingPolicy)  ── mandatory ──► play ~1-min briefing (skippable after 4/type/stage)
      │
run phases in order (WorkoutSessionManager):
   for each ProtocolPhase:
     warmup/block/work:  every 5s safety check (BR-2-23); every 15s CoachingEngineV2.tick;
                         accrue trainingElapsedSec + totalElapsedSec; record hr+phase+phrase
     rest:               instructional only; record; totalElapsed accrues
     buffer (Cont):      slow-walk cue; record tagged buffer
   ── training ends → SESSION COMPLETE & SCORED (SessionScorer)              (BR-2-20)
     transition gate:    show "Ready to stretch? Begin"; totalElapsed PAUSED;
                         HR recorded tagged transition (cap ~5 min idle)      (BR-2-19)
     cooldown:           6 steps, voice + on-screen; record tagged cooldown   (BR-2-17)
      │
closing: spoken tier phrase + visual summary (SessionScore)                   (BR-2-15)
reflection prompt (optional, non-scored)                                      (BR-2-16)
persist session (+ hr_stream w/ phase tags) to Firestore
```

### Two clocks (BR-2-22)
`trainingElapsedSec` freezes at training end (drives scoring, progression, ≥20-min rule). `totalElapsedSec` spans buffer+cooldown, paused during the gate (drives displayed total duration).

### Safety/edge interleave (§J)
Dropout, pause, cancel, walk-fallback handled by the session manager around the tick loop (BR-2-24/25/26/27); emergency stop (BR-2-23) overrides everything except dropout/pause.

## Data flow
```
UserProfileV2 (HRR) ─► ProtocolBuilder ─► WorkoutProtocol (phases + bpm ranges)
HR tick ──► CoachingEngineV2 ─► CoachingMessage ─► voice + text + hr_stream(phrase_type/time)
hr_stream (phase-tagged) ──► SessionScorer ─► SessionScore (percent, tier, zones)
StageProgress + history ──► BriefingPolicy ─► mandatory?
```

## Persistence (extends Phase 1 shapes)
- `sessions`: add `session_flag` (continuous | hiit | walk_fallback), `score_percent`, `score_tier`, `cooldown_skipped`, `training_duration_sec`, `total_duration_sec`.
- `hr_stream` record: add `phase` tag alongside existing `phrase_type`/`phrase_time`.
- All under the existing own-data `users/{uid}` tree; no new auth/consent surface (BR-2-28).

## Testing focus (PBT partial)
- Protocol builder: bpm ranges match spec table across profiles; durations sum correctly.
- CoachingEngineV2: priority ordering; off-zone severity/direction (BR-2-6) exhaustive around the ±5 boundary; escalation timing; no-3×-repeat under seeded RNG; in-zone once-per-block.
- SessionScorer: tier boundaries (89/90, 74/75, 59/60, 39/40); rest/buffer/transition/cooldown excluded; all-in / all-out extremes.
- BriefingPolicy: 0–4 boundary per type per stage.

## Out of scope (later phases)
Exercise phases/leg bank (P4), ratio assignment/progression/relapse (P3), reminders/export/PDF/milestones (P6), Maintain (deferred). Phase 2 selects workouts manually (Q7).
