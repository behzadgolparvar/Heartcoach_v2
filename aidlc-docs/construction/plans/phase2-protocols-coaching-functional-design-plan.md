# Phase 2 — Protocols + Coaching · Functional Design Plan

The specs define protocols (§3) and coaching (§4) in detail. These questions resolve the design decisions that shape the engine and can't be trivially defaulted. Answer after each `[Answer]:` ("Other" to write your own).

## Design steps (tracked)
- [ ] Protocol model (Continuous 7-block, HIIT 15-round/6-block) with per-block %HRR target ranges
- [ ] Coaching engine v2 (priority layers, phrase pools, escalation, transitions, briefing)
- [ ] Session scoring inputs (deferred to Phase 4, but define the time-in-target signal here)
- [ ] Domain entities + business rules

---

## Question 1 — How targets are represented
The specs give each block a **%HRR range** (e.g., 65–75%). v1 used a single zone number per phase.

A) **Explicit %HRR bpm range per block** — compute `[min,max] bpm` from the user's HRR for each block; coaching checks against that range (matches the spec exactly) (recommended)
B) **Map each block to the nearest single zone (1–5)** and reuse v1's zone check (simpler, but loses the precise ranges)
X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 2 — Off-zone deviation measurement
Severity tiers are minor (<5 bpm) / major (≥5 bpm) "off target".

A) Measure bpm distance from the **nearest edge** of the target range (how far below `min` or above `max`) — in-range = 0 off (recommended)
B) Measure from the **midpoint** of the range
X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 3 — In-zone confirmation cadence
Spec says in-zone praise is "rare/occasional, not on a fixed timer."

A) **At most once per block**, only if the user has been in-range for most of that block (deterministic, feels earned) (recommended)
B) **Low fixed probability** per eligible 15s tick (e.g., ~10%) — needs seeded RNG
C) **Every ~90 seconds** of continuous in-range time
X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 4 — Pre-session briefing "first 4 sessions per type" source
The briefing is mandatory for the first 4 sessions of each type, then skippable.

A) **Derive the count** from completed sessions in Firestore (`session_flag` = continuous/hiit) — no new storage (recommended)
B) Keep a **dedicated per-type counter** in the profile/settings
X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 5 — Phrase selection randomness (testability)
Phrase pools rotate (no phrase 3× in a row). Randomness affects testing.

A) **Seeded RNG per session** — varied across sessions but reproducible for tests/PBT (recommended)
B) **True random** (harder to test deterministically)
X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 6 — Coaching engine approach
v1 has a 3-layer `CoachingEngine`. v2's model is richer (5 priority levels, pools, escalation, transitions, briefing).

A) **Rewrite as CoachingEngine v2** — new pure, layered engine (keeps it fully testable), leaving v1 engine untouched until the workout flow switches over (recommended)
B) **Extend the v1 engine** in place
X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 7 — Workout selection in Phase 2
The auto-assignment engine is Phase 3. For Phase 2:

A) **Manual picker** with the two redesigned programs (Continuous / HIIT), Fartlek removed (recommended)
B) Auto-pick a default; no picker
X) Other (please describe after [Answer]: tag below)

[Answer]: 
