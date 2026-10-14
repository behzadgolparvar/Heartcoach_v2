# Phase 2 — Foundation Protocols + Coaching · Functional Design Plan (v5-aligned)

**Scope (v5 re-plan):** the complete **Foundation** (training stage 1) session experience, end-to-end:
Continuous (7 blocks) + HIIT (15 rounds / 6 intensity blocks) · coaching engine v2 · **mandatory cooldown stretch (§F)** · **session scoring (§D/FR-6)** · **safety & edge cases (§J)** · manual workout picker (auto-assignment is Phase 3).
**Spec source:** `hr-coaching-app-full-spec.md` §§Phase 1 (lines 22–53), D, F, J.
**Not in Phase 2:** exercises (Level Up+), progression/ratios (Phase 3), reminders/export/PDF/milestones (Phase 6).

> Updated from the pre-v5 draft: Foundation protocol tables are unchanged, so Q1/Q2/Q6/Q7 stand. Added cooldown stretch + buffer, pulled **scoring into Phase 2** (was deferred to "Phase 4"), added safety/edge, and fixed the briefing to "first 4 per type **per stage**". New questions are Q8–Q11.

## Design steps (tracked)
- [x] Protocol model: Continuous 7-block (§Phase1 table) + HIIT 15-round/6-intensity-block, per-block %HRR→bpm target ranges, fixed 5-min / 1-min timers
- [x] Coaching engine v2: priority layers, phrase pools, escalation, block/round transitions, direction phrases, "N left", pre-session briefing (first 4 per type **per stage**)
- [x] **Cooldown stretch sequence (§F):** 6-step, 2:00, mandatory; +30s slow-walk/breathing buffer after Continuous (none after HIIT)
- [x] **Session scoring (§D/FR-6):** % time in target zone → tier (Excellent/Great/Good/Fair/Needs Work) → spoken closing + visual summary; optional non-scored reflection prompt
- [x] **Safety & edge (§J):** sensor dropout (20s), pause/resume (15-min prompt, 3×10-min snoozes), cancel (≥20 scored / <20 discarded), elevated-starting-HR walk_fallback, voice-off text fallback
- [x] Domain entities + business rules; record `phrase_type`/`phrase_time` into `hr_stream`

---

## Question 1 — How targets are represented
Each block has a **%HRR range** (e.g. 65–75%). v1 used a single zone number per phase.

A) **Explicit %HRR bpm range per block** — compute `[min,max] bpm` from the user's HRR for each block; coaching checks against that range (matches the spec exactly) (recommended)
B) **Map each block to the nearest single zone (1–5)** and reuse v1's zone check (simpler, loses the precise ranges)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2 — Off-zone deviation measurement
Severity tiers are minor (<5 bpm) / major (≥5 bpm) off target.

A) Measure bpm distance from the **nearest edge** of the target range (how far below `min` or above `max`) — in-range = 0 off (recommended)
B) Measure from the **midpoint** of the range
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3 — In-zone confirmation cadence
Spec says in-zone praise is "rare/occasional, not on a fixed timer."

A) **At most once per block**, only if the user has been in-range for most of that block (deterministic, feels earned) (recommended)
B) **Low fixed probability** per eligible 15s tick (e.g. ~10%) — needs seeded RNG
C) **Every ~90 seconds** of continuous in-range time
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4 — Pre-session briefing "first 4 sessions per type per stage" source
v5 §D: briefing is mandatory for the first 4 sessions of each type **within the current training stage**, then skippable.

A) **Derive the count** from the current stage's `StageProgress` + per-type completed sessions (reuses the P1b program state; no new storage) (recommended)
B) Keep a **dedicated per-type, per-stage counter** in the profile/settings
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5 — Phrase selection randomness (testability)
Phrase pools rotate (no phrase 3× in a row). Randomness affects testing.

A) **Seeded RNG per session** — varied across sessions but reproducible for tests/PBT (recommended)
B) **True random** (harder to test deterministically)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6 — Coaching engine approach
v1 has a 3-layer `CoachingEngine`. v2's model is richer (5 priority levels, pools, escalation, transitions, briefing).

A) **Rewrite as CoachingEngine v2** — new pure, layered engine (fully testable), leaving the v1 engine untouched until the workout flow switches over (recommended)
B) **Extend the v1 engine** in place
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 7 — Workout selection in Phase 2
The auto-assignment/progression engine is Phase 3. For Phase 2:

A) **Manual picker** with the two Foundation programs (Continuous / HIIT) (recommended)
B) Auto-pick a default; no picker
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---
## New v5 questions (Q8–Q11)

## Question 8 — Cooldown stretch representation
v5 §F: a fixed 6-step, 2:00 stretch sequence ends **every** session (quad 30s, hamstring 15s, calf 30s, overhead 15s, adductor 15s, frog sit 15s), announced as mandatory.

A) **Model it as a timed post-training "cooldown phase"** in the protocol timeline (its own phase after Block 7 / Round 15), with per-step voice cues + on-screen step list; not HR-coached, safety still passive (recommended)
B) Model it as a **separate non-workout screen** shown after the session ends (outside the protocol timeline)
X) Other (please describe after [Answer]: tag below)

[Answer]: A — plus a user-paced "ready to stretch" gate between the buffer (Continuous) / final walk (HIIT) and the 2-min stretch sequence. The stretch timer starts only when the user taps "Begin". During the gate the total-session clock pauses and HR keeps recording tagged `transition`; the session is already complete/scored at end of training, so an abandoned gate just logs a skipped cooldown and finalizes after a timeout.

> ⚑ PRODUCT CLARIFICATION FOR COLLABORATOR: §F does not account for the physical transition off a treadmill. We inserted a user-paced "ready to stretch" gate before the mandatory stretch sequence (you can't switch to standing stretches instantly). Flag for confirmation.

**Cooldown arc (Q8+Q9):** …Block 7 → [buffer: 30s, Continuous only] → [transition gate: tap to begin] → Cooldown stretch (2:00, 6 steps) → complete. Two clocks: `training time` (ends at Block 7, used for scoring/progression/≥20-min rule) and `total session time` (spans buffer+cooldown, paused during the gate). HR stream is continuous and per-second with a `phase`/segment tag (`warmup/block/rest/buffer/transition/cooldown`) so scoring (Q11) excludes non-training phases from the denominator while still recording them.

## Question 9 — Continuous 30-sec buffer
v5 §F: after Continuous (ends running) there's a **30-sec slow-walk + breathing buffer** before the stretch; HIIT (ends walking) goes straight to the stretch.

A) **Make the buffer a Continuous-only timeline segment** between training and cooldown (HIIT omits it) — deterministic, timer-driven (recommended)
B) Fold the buffer into the first stretch step's intro
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 10 — Score tiers → percentage thresholds
Score = % time in target zone → tier (Excellent/Great/Good/Fair/Needs Work). The spec names the tiers but not the cutoffs.

A) **≥90 Excellent · 75–89 Great · 60–74 Good · 40–59 Fair · <40 Needs Work** (even, intuitive bands) (recommended)
B) **≥85 / 70 / 55 / 40 / <40** (more forgiving top tier)
C) Let me specify the exact cutoffs
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 11 — "Time in target" signal for scoring
Scoring needs a per-second in/out-of-target signal across the whole session.

A) **Count a second as "in target" when HR is within that block's %HRR bpm range** (reuses Q1's per-block ranges); warm-up counted, rest/cooldown/buffer excluded from the denominator (recommended)
B) Count against a single session-wide target zone
C) Include rest phases in the denominator too
X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### After answers
I'll generate the functional-design artifacts under `aidlc-docs/construction/phase2-foundation/functional-design/` (business-logic-model, business-rules, domain-entities), then present the 2-option completion gate.
