# Phase 2 — Domain Entities (Foundation Protocols + Coaching)

Technology-agnostic. All logic lands in `HeartRateCoachCore` (pure, testable); the app wires UI/voice/Watch. Decisions: Q1–Q11 all A (Q8 A + transition gate).

## 1. Protocol model

### `WorkoutType`
`continuous | hiit` (Foundation only; Fartlek removed). Level Up / Shape extend later.

### `TargetRange`
A per-block heart-rate target computed from the user's HRR (Q1=A).
- `lowPctHRR: Double`, `highPctHRR: Double` (e.g. 0.75, 0.85)
- `func bpmRange(restingHR:maxHR:) -> ClosedRange<Int>` — Karvonen: `rhr + pct·(maxHR − rhr)`, rounded.

### `PhaseKind` (segment tag — drives scoring + recording)
`warmup | block | work | rest | buffer | transition | cooldown`
- `warmup`, `block` (Continuous), `work` (HIIT round work) → **scored** (counted in denominator, Q11).
- `rest`, `buffer`, `transition`, `cooldown` → recorded but **excluded** from the scoring denominator.

### `ProtocolPhase`
One timed segment of a session.
- `index: Int`, `kind: PhaseKind`
- `durationSec: Int?` — nil for the `transition` gate (user-paced, Q8).
- `target: TargetRange?` — present for `warmup/block/work`; nil otherwise.
- `isHRCoached: Bool` — true only for `warmup/block/work`; false for rest/buffer/transition/cooldown.
- `label: String` — e.g. "Block 5 — Peak", "Round 9", "Quad stretch".

### `WorkoutProtocol`
The full deterministic timeline for a session.
- `type: WorkoutType`
- `phases: [ProtocolPhase]`
- `trainingDurationSec: Int` — sum of scored-phase durations (the 35:00).
- Built by `FoundationProtocolBuilder` (below) from the spec tables.

### Foundation timelines (from spec §Phase 1)
**Continuous:** warm-up is Block 1. 7 blocks × 5:00, targets 50–60 / 60–70 / 65–75 / 70–80 / 75–85 / 70–80 / 75–85 %HRR. Then `buffer` 30s → `transition` (gate) → `cooldown` (6 steps, 2:00).
**HIIT:** 5:00 warm-up (target 65–75 to match round 1–2), then 15 rounds of `work` 60s / `rest` 60s. Work targets by round group (6 intensity blocks): 1–2 65–75, 3–5 70–80, 6–8 75–85, 9–11 80–90, 12–13 75–85, 14–15 80–90 %HRR. Then `transition` (gate) → `cooldown` (no buffer).

### `CooldownStep` (§F)
Fixed 6-step sequence (same all stages/types):
`quad(30) · hamstring(15) · calf(30) · overheadReach(15) · adductor(15) · frogSit(15)` = 120s. Each → a `cooldown` ProtocolPhase with voice cue + on-screen label.

## 2. Coaching model (§D)

### `CoachingPriority` (highest → lowest)
`safety > endOfPhase > escalation > offZone > inZone > transition`
(Exactly one message selected per tick by priority.)

### `Severity` / `Direction`
- `Severity`: `minor` (<5 bpm off) · `major` (≥5 bpm off) (Q2 edge-distance).
- `Direction`: `low` (below range) · `high` (above range).

### `PhrasePool`
A named pool of 5–6 interchangeable phrasings for one (priority, severity, direction) situation, plus block/round transitions, "N left", briefing, closing-by-tier.
- `id: PhraseCategory`, `variants: [String]`
- Selection honors **no-same-phrase-3×-in-a-row** via seeded RNG (Q5).

### `CoachingMessage`
What the engine emits for a tick.
- `text: String`, `category: PhraseType`, `priority: CoachingPriority`
- `atSec: Int` (session time) → recorded as `phrase_type` + `phrase_time` in `hr_stream`.

### `CoachingState` (per session, mutable)
- recent phrase ids per pool (for the 3× rule)
- off-zone run length per phase (for escalation: HIIT 30s / Cont 60s)
- in-zone progress per block (for once-per-block confirmation, Q3)
- seeded RNG

### `BriefingPolicy`
Decides if the pre-session briefing is mandatory (Q4=A): counts completed **scored** sessions of this `WorkoutType` **in the current `TrainingStage`** (from `StageProgress` + session history); mandatory while `< 4`, else skippable.

## 3. Session scoring (§D/FR-6)

### `SessionScore`
- `percentInTarget: Double` — scored-seconds-in-range / total-scored-seconds (Q11).
- `tier: ScoreTier`
- `timeInZoneSec: [Int: Int]` — seconds per zone 1–5 (visual summary).

### `ScoreTier` (Q10=A)
`excellent (≥90) · great (75–89) · good (60–74) · fair (40–59) · needsWork (<40)`
- `static func from(percent:) -> ScoreTier`
- `var closingPhrasePool: PhraseCategory` — tier-matched spoken closing.

## 4. Session lifecycle & timing (Q8)

### Two clocks
- `trainingElapsedSec` — accrues only during scored phases; freezes at end of last work block. Drives scoring, progression, and the ≥20-min cancel rule (§J).
- `totalElapsedSec` — accrues across buffer + cooldown; **paused during the `transition` gate**; drives the session record's total duration.

### `SessionCompletion`
A session is **complete at end of training** (last scored phase). Buffer/transition/cooldown are post-completion. An abandoned transition gate → `cooldownSkipped = true`, finalize after timeout.

### `HRRecord` (extend existing)
Per-second: `timeSec`, `bpm`, existing `phrase_type?`/`phrase_time?`, **+ `phase: PhaseKind`** (new) so scoring/export can filter. Recording is continuous warm-up → cooldown; transition recorded (capped if idle) and tagged.

## 5. Safety & edge (§J) — entities
- `SensorDropoutState`: 20s no reading → prompt; resume in place; gap flagged; safety-unavailable warning.
- `PauseState`: 15-min prompt (Continue/Finish/Need More Time), max 3 snoozes × 10 min; safety off while paused (user informed).
- `CancelRule`: `trainingElapsedSec ≥ 20min` → scored; `< 20min` → discarded.
- `WalkFallback`: elevated starting HR → 5-min walk check → settled? normal : full-session 1-min fast/1-min slow; logged `walk_fallback`, excluded from progression stats (Phase 3), retained for research.
- Voice-off: every `CoachingMessage` has on-screen text equivalent (already v1 pattern).
