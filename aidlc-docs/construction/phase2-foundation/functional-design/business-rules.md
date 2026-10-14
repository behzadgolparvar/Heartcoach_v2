# Phase 2 — Business Rules (Foundation Protocols + Coaching)

`BR-2-*` namespace. All rules deterministic / PBT-targetable unless noted.

## Protocol construction
- **BR-2-1 (target bpm):** for each scored phase, `bpm = round(restingHR + pct·(maxHR − restingHR))` for both edges; `maxHR = profile.effectiveMaxHR`. Range is `[lowBpm, highBpm]`.
- **BR-2-2 (Continuous timeline):** 7 blocks × 300s with the §Phase1 %HRR table; Block 1 = warm-up. Append `buffer`(30s) → `transition`(gate) → 6 `cooldown` steps (120s). `trainingDurationSec = 2100` (35:00).
- **BR-2-3 (HIIT timeline):** `warmup`(300s, 65–75%) then 15×(`work`60s / `rest`60s) with the 6-block %HRR groups; append `transition`(gate) → 6 `cooldown` steps. No buffer. `trainingDurationSec = 300 + 15·60 = 1200` work+warmup counted; rest excluded from denominator (BR-2-12).
- **BR-2-4 (target updates on timer):** `target_zone` changes only at phase boundaries (fixed 5:00 Continuous / per-round HIIT); never mid-phase.

## Coaching selection (per 15s tick; safety per 5s)
- **BR-2-5 (priority):** emit at most one message, highest priority first: safety → end-of-phase(last 10s) → escalation → off-zone → in-zone → transition. Lower priorities suppressed that tick.
- **BR-2-6 (off-zone distance, Q2):** `off = max(0, lowBpm − hr, hr − highBpm)`; in-range ⇒ 0. `minor` if `0 < off < 5`, `major` if `off ≥ 5`. `direction = hr < lowBpm ? .low : .high`.
- **BR-2-7 (escalation):** sustained off-zone ≥ 30s (HIIT) / 60s (Continuous) raises an escalation message; the run-length counter resets the instant HR re-enters range.
- **BR-2-8 (in-zone confirmation, Q3):** at most one per block/round, only if in-range for the majority of that phase; deterministic (no probability).
- **BR-2-9 (no-repeat rotation, Q5):** never select a phrase equal to either of the last two chosen from the same pool; selection uses the session's seeded RNG (reproducible for tests).
- **BR-2-10 (rest phases):** during HIIT `rest`, no zone coaching and no off-zone/escalation; only instructional/direction text. Safety still active.
- **BR-2-11 (briefing, Q4):** mandatory when completed **scored** sessions of this type in the current stage `< 4`; else skippable. Count derived from session history + `StageProgress` (no new counter). `walk_fallback` and <20-min discards don't count.

## Scoring (§D/FR-6)
- **BR-2-12 (in-target second, Q11):** a second counts in-target iff its phase is scored (`warmup/block/work`) and `hr ∈ target bpm range` for that phase. Denominator = all scored seconds. `rest/buffer/transition/cooldown` excluded from numerator and denominator.
- **BR-2-13 (percent):** `percentInTarget = scoredInRangeSeconds / max(1, totalScoredSeconds) · 100`.
- **BR-2-14 (tiers, Q10):** `≥90 excellent · 75–89 great · 60–74 good · 40–59 fair · <40 needsWork`. Boundaries inclusive at the lower number.
- **BR-2-15 (closing + summary):** spoken closing drawn from the tier-matched pool (BR-2-9 rotation applies); visual summary shows percent, tier, and per-zone seconds.
- **BR-2-16 (reflection):** optional, non-scored, post-session; never affects score or progression.

## Cooldown & timing (Q8/Q9)
- **BR-2-17 (cooldown mandatory, announced):** every session ends with the 6-step §F sequence; app announces it as mandatory for injury prevention. Not HR-coached.
- **BR-2-18 (buffer):** Continuous inserts a 30s `buffer` (slow walk + breathing) before the transition gate; HIIT omits it (already walking).
- **BR-2-19 (transition gate):** after buffer/final walk, the stretch timer does **not** auto-start; it starts on the user's "Begin" tap. `totalElapsedSec` pauses during the gate; HR keeps recording tagged `transition` (cap appending after ~5 min idle).
- **BR-2-20 (completion):** session is complete/scored at end of the last scored phase (training). Abandoning the gate or cooldown ⇒ `cooldownSkipped = true`, finalize after timeout; score unaffected.

## Recording
- **BR-2-21 (continuous stream):** `hr_stream` is per-second from warm-up through cooldown; each record tagged with its `PhaseKind`. `phrase_type`/`phrase_time` set on the second a message is emitted.
- **BR-2-22 (two clocks):** `trainingElapsedSec` accrues only in scored phases (freezes at training end); `totalElapsedSec` spans buffer+cooldown, paused during the gate.

## Safety & edge (§J)
- **BR-2-23 (safety always on):** HR > `effectiveMaxHR` triggers emergency stop in every phase except during sensor-dropout/pause (user informed), including cooldown.
- **BR-2-24 (dropout):** 20s no reading → prompt; resume in place; mark data gap; warn safety temporarily unavailable.
- **BR-2-25 (pause):** 15-min prompt (Continue/Finish/Need More Time), max 3 snoozes ×10 min; safety off while paused.
- **BR-2-26 (cancel):** `trainingElapsedSec ≥ 1200` (20 min) ⇒ scored & saved; `< 1200` ⇒ discarded.
- **BR-2-27 (walk fallback):** elevated starting HR → 5-min walk check; settled ⇒ normal session; else full-session 1:1 fast/slow walk, flagged `walk_fallback`, excluded from progression stats, retained for research.

## Security (inherited, blocking)
- **BR-2-28:** HR values, targets, scores, phrase content tied to a user are health/PII — never console/analytics-logged (SECURITY-03). `hr_stream`/scores persist under the existing own-data Firestore doc; consent already gated at onboarding.
