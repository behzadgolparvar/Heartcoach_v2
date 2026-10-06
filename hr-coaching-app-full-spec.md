# HR Coaching App — Complete Development Specification (v5)

**Platform:** iPhone only
**Entry requirement:** Healthy individuals only — no diagnosed patients enrolled at this stage.
**Positioning:** Built specifically for overweight, sedentary, or first-time-exerciser adults who don't know how to start — a guided program, not a workout tracker.

**Program Structure — 4 Phases:**

| Phase | Client-Facing Name | Internal Name | Content |
|---|---|---|---|
| 1 | Foundation | Ignite | Pure Continuous/HIIT, HR-zone based |
| 2 | Level Up | Concurrent | Continuous/HIIT + bodyweight leg exercises |
| 3 | Shape | Body Shape Focus | Continuous/HIIT + daily client choice: Option A (plyometric) / Option B (weight training) |
| 4 | Maintain | Lifestyle | Long-term maintenance (not yet designed) |

Each phase: own independent 60-session counter, own 3 sub-phases of 20 sessions each (ratio-progression, session-count gated), own phase-specific unlock question set. Classification (Beginner/Intermediate/Advanced) carries forward unchanged across all phases.

**Every session across all phases ends with a mandatory 2-minute cooldown stretch** (see Section F). Continuous sessions add a 30-sec slow-walk/breathing buffer before the stretch; HIIT sessions go straight into the stretch (already at low intensity from the final walk).

---

## PHASE 1 — FOUNDATION

**Continuous (35:00 training + 0:30 buffer + 2:00 cooldown = 37:30 total)**

7 progressive blocks, 5:00 each:

| Block | Zone / %HRR |
|---|---|
| 1 (warm-up) | Zone 1, 50–60% |
| 2 | Zone 2, 60–70% |
| 3 | Zone 2–3, 65–75% |
| 4 | Zone 3, 70–80% |
| 5 (peak) | Zone 3–4, 75–85% |
| 6 (ease back) | Zone 3, 70–80% |
| 7 (finish) | Zone 3–4, 75–85% |

`target_zone` updates on a fixed 5-min timer. No exercise blocks in Foundation — pure running throughout.

**HIIT (35:00 training + 2:00 cooldown = 37:00 total)**

5-min warm-up, then 15 rounds of 1-min work / 1-min rest:

| Rounds | Work %HRR |
|---|---|
| 1–2 | 65–75% |
| 3–5 | 70–80% |
| 6–8 | 75–85% |
| 9–11 | 80–90% |
| 12–13 | 75–85% (ease) |
| 14–15 | 80–90% (finish) |

Rest = unmonitored walking ("Take a walk, normal pace"). Safety layer always active. "Block" = intensity-range change (6 true blocks), not every round.

---

## PHASE 2 — LEVEL UP

**Own 60-session counter.** Same ratio-progression framework as Foundation (see Section B). Exercise bank: 20+ standing bodyweight leg exercises (rotating random selection); no exercise progression across sub-phases — only the HIIT:Continuous ratio changes.

### 2.1 Continuous (35:00 training + 0:30 buffer + 2:00 cooldown = 37:30 total)

**7 blocks, 5:00 each** — warm-up (Block 1) includes its own exercise phase, same as every other block except the last.

| Block | Time | Zone / %HRR |
|---|---|---|
| 1 (warm-up) | 0:00–5:00 | Zone 1, 50–60% |
| 2 | 5:00–10:00 | Zone 2, 60–70% |
| 3 | 10:00–15:00 | Zone 2–3, 65–75% |
| 4 | 15:00–20:00 | Zone 3, 70–80% |
| 5 (peak) | 20:00–25:00 | Zone 3–4, 75–85% |
| 6 (ease back) | 25:00–30:00 | Zone 3, 70–80% |
| 7 (finish, no exercise) | 30:00–35:00 | Zone 3–4, 75–85% |

**Internal timeline, Blocks 1–6 (each 5:00):**

| Time (relative) | What happens |
|---|---|
| 0:00–3:50 | Run in target zone |
| 3:35 | Last zone feedback (quiet buffer starts) |
| 3:50–4:00 | Talk: introduces exercise + visualization |
| 4:00–4:30 (bilateral) / 4:00–4:32 (unilateral) | Exercise — synced count |
| Immediately after | "Announce slow walk" cue |
| → 5:00 | Walking (no feedback) |
| 4:50 | "Announce next phase" cue (still walking) |

**Block 7:** Full 5:00 running, no exercise, session ends into cooldown.

**Exercise:** Bilateral = 30 sec (15 reps); Unilateral = 32 sec (8 reps/leg). Type per block: fully random from the leg exercise bank.

### 2.2 HIIT (35:00 training + 2:00 cooldown = 37:00 total)

| Segment | Time | Zone / %HRR |
|---|---|---|
| Warm-up | 0:00–3:00 | Zone 1 |
| Exercise Block (post-warmup) | 3:00–5:00 | — |
| Round 1 | 5:00–8:00 | 65–75% |
| Round 2 | 8:00–11:00 | 70–80% |
| Round 3 | 11:00–14:00 | 70–80% |
| Round 4 | 14:00–17:00 | 75–85% |
| Round 5 | 17:00–20:00 | 75–85% |
| Round 6 | 20:00–23:00 | 80–90% |
| Round 7 | 23:00–26:00 | 80–90% |
| Round 8 | 26:00–29:00 | 75–85% (ease) |
| Round 9 | 29:00–32:00 | 80–90% (finish) |
| Round 10 | 32:00–35:00 | 80–90% (finish) |

**Each round (3:00):** 1:00 run → walk begins + exercise-intro talk (1:00–1:10) → exercise, synced count, 20 reps (1:10–2:10) → walk continues, no feedback (2:10–3:00). Session ends on Round 10's walk, straight into cooldown.

---

## PHASE 3 — SHAPE

**Unlocks after Level Up's 60 sessions**, via its own unlock question set (Section E). **Own 60-session counter.** Same ratio-progression framework.

**Daily choice (every session, not locked once):**
- **Option A** — Outdoor, no equipment: plyometric leg exercises, 20 reps/min
- **Option B** — Treadmill + free weights: client selects & ranks exactly 2 muscle groups per session (priority + secondary), 30 reps of one exercise per phase (~2 sec/rep)

**Legs rule:** if Legs is chosen (priority or secondary) in Option B, Legs' phases always use plyometric exercises; the other chosen muscle uses weight training. A session can mix both types.

**Equipment guidance (Option B):** weight should be light-to-moderate, scaled to the client's body weight (e.g., a guideline like 5–10% of body weight per hand for arm work), enough that 30 reps is completable without excessive strain. No formal equipment inventory required.

### 3.1 Continuous (35:00 training + 0:30 buffer + 2:00 cooldown = 37:30 total)

**7 blocks** — Block 1 (warm-up) full-length; Blocks 2–6 shortened run to compensate for extended 2:10 exercise phases; Block 7 pure run finish.

| Block | Time | Zone / %HRR | Exercise Phase # |
|---|---|---|---|
| 1 (warm-up) | 0:00–6:00 | Zone 1, 50–60% | 1 |
| 2 | 6:00–11:00 | Zone 2, 60–70% | 2 |
| 3 | 11:00–16:00 | Zone 2–3, 65–75% | 3 |
| 4 | 16:00–21:00 | Zone 3, 70–80% | 4 |
| 5 (peak) | 21:00–26:00 | Zone 3–4, 75–85% | 5 |
| 6 (ease back) | 26:00–31:00 | Zone 3, 70–80% | 6 |
| 7 (finish, no exercise) | 31:00–35:00 | Zone 3–4, 75–85% | — |

**Internal timeline, Block 1 (6:00):** Run 0:00–3:50 → talk 3:50–4:00 → exercise 4:00–5:00 (1:00, 20 or 30 reps) → rest/breathing 5:00–5:10 → walk 5:10–6:00.

**Internal timeline, Blocks 2–6 (5:00 each):** Run (2:50) → talk (0:10) → exercise (1:00) → rest/breathing (0:10) → walk (0:50). Example, Block 2: Run 6:00–8:50 → talk 8:50–9:00 → exercise 9:00–10:00 → rest 10:00–10:10 → walk 10:10–11:00.

**Exercise phase alternation (Option B, 6 phases total): 4-2 split, priority gets the extra phases:**

| Phase | Muscle |
|---|---|
| 1 | Priority (A) |
| 2 | Secondary (B) |
| 3 | Priority (A) |
| 4 | Secondary (B) |
| 5 | Priority (A) |
| 6 | Priority (A) |

**Total: 35:00 exactly.**

### 3.2 HIIT (35:10 training + 2:00 cooldown = 37:10 total)

11 exercise phases (0 post-warmup + 10 within rounds) vs. 10 run segments to absorb the added time — results in a 10-sec overage, accepted as-is.

| Segment | Time | Zone / %HRR |
|---|---|---|
| Warm-up | 0:00–3:00 | Zone 1 |
| Exercise Phase 0 | 3:00–5:10 | — |
| Round 1 — Run | 5:10–6:00 (0:50) | 65–75% |
| Exercise Phase 1 | 6:00–8:10 | — |
| Round 2 — Run | 8:10–9:00 (0:50) | 70–80% |
| Exercise Phase 2 | 9:00–11:10 | — |
| Round 3 — Run | 11:10–12:00 (0:50) | 70–80% |
| Exercise Phase 3 | 12:00–14:10 | — |
| Round 4 — Run | 14:10–15:00 (0:50) | 75–85% |
| Exercise Phase 4 | 15:00–17:10 | — |
| Round 5 — Run | 17:10–18:00 (0:50) | 75–85% |
| Exercise Phase 5 | 18:00–20:10 | — |
| Round 6 — Run | 20:10–21:00 (0:50) | 80–90% |
| Exercise Phase 6 | 21:00–23:10 | — |
| Round 7 — Run | 23:10–24:00 (0:50) | 80–90% |
| Exercise Phase 7 | 24:00–26:10 | — |
| Round 8 — Run | 26:10–27:00 (0:50) | 75–85% (ease) |
| Exercise Phase 8 | 27:00–29:10 | — |
| Round 9 — Run | 29:10–30:00 (0:50) | 80–90% (finish) |
| Exercise Phase 9 | 30:00–32:10 | — |
| Round 10 — Run | 32:10–33:00 (0:50) | 80–90% (finish) |
| Exercise Phase 10 | 33:00–35:10 | — |

**Total: 35:10.** Session ends on Exercise Phase 10's walk, straight into cooldown (no buffer needed, already low-intensity).

**Zone feedback in 50-sec runs:** 2 checks per run segment (special-case timing, not standard 15-sec cycle).

**Each exercise phase internally (2:10):** Talk (0:10) → Exercise, 20 reps plyometric or 30 reps weight training (1:00) → Rest/breathing (0:10) → Walk (0:50).

**Muscle alternation (11 phases, 0–10): priority opens and gets 6, secondary gets 5:**

| Phase | Muscle |
|---|---|
| 0 | Priority |
| 1 | Secondary |
| 2 | Priority |
| 3 | Secondary |
| 4 | Priority |
| 5 | Secondary |
| 6 | Priority |
| 7 | Secondary |
| 8 | Priority |
| 9 | Secondary |
| 10 | Priority |

**Legs rule** applies identically to Continuous.

---

## PHASE 4 — MAINTAIN

Not yet designed. Future work.

---

## SHARED SYSTEMS

### A. Experience Classification

**Q1 (authoritative):** Training history duration → Beginner (never/1+ yr gap) / Intermediate (<1 yr consistent, or recent return) / Advanced (1+ yr consistent). Honesty-framing prompt included.
**Q2 (self-select, independent):** Same three tiers, shown with plain-language definitions, without revealing Q1's result.

**Resolution:**

| Q1 | Q2 | Result |
|---|---|---|
| Beginner | Advanced | Intermediate (mismatch override, logged internally) |
| Advanced | Beginner | Intermediate (mismatch override, logged internally) |
| Any other combo | — | Q1 wins |

**Ozempic/GLP-1 override:** "Yes" → automatically Beginner, overriding Q1/Q2. Editable anytime; No→Yes re-triggers override + informational popup; Yes→No re-runs Q1/Q2 classification. Q1/Q2 always asked regardless, for research data.

**Ozempic flow:** Popup: *"Research shows that combining exercise with GLP-1 medications like Ozempic is linked to greater fat loss and better weight-loss maintenance after stopping the medication."* → confirm → *"Your training will start at a Beginner level to build a strong, sustainable foundation alongside your medication."*

Classification carries forward unchanged across all 4 phases — no reclassification between phases.

### B. Ratio Progression (60 Sessions / 3 Sub-Phases of 20, Per Phase)

**Beginner — Fast Weight Loss:**

| Mentality | Sub-Phase 1 (1–20) | Sub-Phase 2 (21–40) | Sub-Phase 3 (41–60) |
|---|---|---|---|
| Outcome-focused | 1:2 | 1:1 | 2:1 |
| Mixed | 1:3 | 1:2 | 1:1 |
| Process-focused | 1:4 | 1:3 | 1:2 |

**Beginner — Routine/Cardio Fitness:** Continuous only (occasional HIIT ~1-in-4 if outcome-focused).

**Intermediate:**

| Mentality | Sub-Phase 1 | Sub-Phase 2 | Sub-Phase 3 |
|---|---|---|---|
| Outcome-focused | 1:1 | 2:1 | 3:1 |
| Mixed | 1:2 | 1:1 | 2:1 |
| Process-focused | 1:3 | 1:2 | 1:1 |

**Advanced:**

| Mentality | Sub-Phase 1 | Sub-Phase 2 | Sub-Phase 3 |
|---|---|---|---|
| Outcome-focused | 2:1 | 3:1 | 4:1 |
| Mixed | 1:1 | 2:1 | 3:1 |
| Process-focused | 1:2 | 1:1 | 2:1 |

No manual intensity scaling by experience level — %HRR zones already account for fitness differences; only the ratio differs. Frequency-based completion incentive: 5x/week ≈ 3 months, 4x/week ≈ 3.5 months, 3x/week ≈ 4.5–5 months per phase's 60 sessions.

### C. Relapse / Re-Entry Handling (Per-Phase)

| Gap | Consequence |
|---|---|
| ≤1 week | No penalty |
| 2 weeks | Push back 3 sessions |
| 3 weeks | Push back 5 sessions |
| 1 month | Push back 8 sessions |
| >1 month | Reset to starting sub-phase |

Non-negotiable minimum sessions prevent relapse-clock advancement without counting toward progression. Framing always positive.

### D. Real-Time Feedback System

Priority: Safety stop > End-of-phase message > Escalation > Standard zone feedback > Round/block-start announcement.
Off-zone check every 15 sec (standard) / 2 checks per 50-sec Shape HIIT run (special case). In-zone confirmation rare. No-repeat rule (5–6 phrase pools, no 3x-consecutive repeat).
Off-zone tiers: Minor (<5bpm)/Major(5+bpm) × Low/High = 4 phrase pools (see v3 spec for full phrase lists).
Escalation: 30 sec (HIIT) / 60 sec (Continuous) sustained off-zone.
Pre-session briefing: 1 min, rotating scripts, mandatory first 4 sessions per workout type per phase, skip-option after.
Post-session score: % time in target zone → tier (Excellent/Great/Good/Fair/Needs Work) → spoken + visual summary.
Reflection prompt: optional, non-scored, post-session.

### E. Phase Unlock Question Sets

**Level Up unlock (asked once, entering Phase 2):**
1. "Have you had any leg, knee, hip, or ankle injuries in the past year?"
   - **If Yes:** follow-up "Which area?" (knee/hip/ankle/general leg) → app excludes high-impact/high-load exercises for that joint from the rotation (e.g., knee issue excludes deep lunges/jump-style movements) → caution message shown: *"Since you mentioned a recent injury, we've adjusted your exercises. If you feel pain during any movement, stop and consult a doctor before continuing."*
2. "Are you comfortable doing bodyweight exercises like squats or lunges?"
   - **If No:** client is shown the full leg-exercise list (with visuals/descriptions) and pre-selects which they're willing/able to do; the app's random rotation pulls only from this approved subset.

**Shape unlock (asked once, entering Phase 3):**
1. "Do you have access to a treadmill and free weights, or would you prefer outdoor/no-equipment training?" — sets default starting preference (both options remain available every session going forward).
2. "Have you experienced any pain or discomfort during Level Up sessions?" — safety check before increasing complexity.
3. "Which areas would you like to focus on most?" — primes the client for the muscle-group selection they'll make each session.

**Note:** Equipment preference and focus-area selection (Shape's Q1 and Q3 content) are also asked **per session**, not just at unlock — the unlock questions set an initial default/readiness check, but the actual daily choice happens each time the client starts a session.

### F. Mandatory Cooldown Stretch (All Phases, All Types)

2 minutes, applied at the end of every session, after training completes:

| Stretch | Hold | Notes |
|---|---|---|
| Quad stretch | 15s each leg (30s) | |
| Hamstring stretch | 15s | Bend and reach |
| Calf stretch | 15s each leg (30s) | |
| Overhead reach | 15s | Straight arms up |
| Adductor stretch | 15s | Open up, bend and reach |
| Frog sit | 15s | |

**Total: 2:00.** App announces this is mandatory for health/injury-prevention purposes.

**Transition into cooldown:**
- **After Continuous** (ends in running): 30-sec slow walk + deep breathing buffer, then stretch sequence.
- **After HIIT** (ends in walking): straight into stretch sequence, no buffer needed.

### G. Exercise Banks

**Legs (plyometric, standing, Option A / Level Up base):**
Squat jumps, jumping lunges (alternating), lateral bounds, step-up jumps, skater jumps, jump rope (or phantom motion), broad jumps, split squat jumps. (Bank of 8+; rotate 6+ per session.)

**Chest (standing, free weight):**
Standing dumbbell chest press, standing dumbbell fly, standing chest squeeze press, standing incline press, standing single-arm cross-body press, standing dumbbell pullover.

**Back (standing, free weight):**
Standing bent-over row, standing single-arm row, standing reverse fly, standing dumbbell shrugs, standing "W" raises, standing band/dumbbell pull-apart.

**Shoulders (standing, free weight):**
Standing dumbbell shoulder press, standing lateral raise, standing front raise, standing Arnold press, standing upright row, standing alternating shoulder press.

**Arms (standing, free weight):**
Standing bicep curl, standing hammer curl, standing overhead triceps extension, standing triceps kickback, standing concentration-style curl, standing dumbbell punch/press-out.

**Abs (standing, free weight/bodyweight):**
Standing dumbbell side bend, standing woodchopper, standing bicycle crunch (knee-to-elbow), standing overhead reach and twist, standing high knee with twist, standing weighted torso twist.

All exercises across all six groups are fully standing — no floor transitions.

### H. Outcome-Based Milestones

Resting HR (app-monitored) + Weight (self-reported), both biweekly, in the morning. Weight entry: Day 1 missed = reminder; Day 2 missed = blocked until logged.

### I. Non-Negotiable Minimum

15-min walk (8 min fast / 7 min slow), fallback for low-motivation days. Doesn't count toward progression; prevents relapse-clock advancement.

### J. Safety & Edge Cases

- **Sensor dropout:** 20 sec no reading → prompt; resumes without restart.
- **Pause/Resume:** timer holds; 15-min prompt (Continue/Finish/Need More Time, max 3 snoozes, 10-min each).
- **Cancel/Incomplete:** ≥20 min scored; <20 min discarded.
- **Elevated starting HR:** 5-min walk check → normal session if settled, else 1-min fast/1-min slow walk intervals for the full session (`walk_fallback` flag, excluded from stats, retained for research).
- **Voice-off/silent mode:** all spoken messages have on-screen text/visual fallback.

### K. Client-Facing Session Plan (PDF, Per Phase)

Delivered post-onboarding and at the start of each subsequent phase. Indexed by session number, not calendar date. Includes: projected completion note (frequency-based, framed toward next phase), column key, miss-session rules (including non-negotiable minimum), and the full session-by-session table (Session #, Type, Focus + What to Expect rotating pairs, Intensity, Duration).

---

## SCIENTIFIC BASIS FOR OZEMPIC/GLP-1 CLAIMS

Supported by human RCT evidence: exercise + GLP-1 therapy improves weight-loss **maintenance** after stopping medication, and is associated with **greater reductions in abdominal fat/obesity**, versus medication alone. **Not supported for this app:** muscle-mass preservation claims — that benefit in the literature is tied to resistance training + high protein diet specifically, not aerobic HR-zone training alone. Avoid this claim.

---

## TECHNICAL DECISIONS REQUIRED (DEVELOPER-OWNED)

These require technical expertise/judgment during build — flag and resolve with your development team directly, not product decisions for the founder to make:

1. **Call reminders** — requires a calling API (e.g., Twilio) with TTS for automated voice calls; evaluate feasibility/cost vs. a push-notification equivalent carrying the same message content.
2. **Firestore security rules** — implement rules ensuring users can only read/write their own data.
3. **OS permissions** — proper request flows for HealthKit background access and push notifications.
4. **Data gap handling** — ensure graphing/analysis tools handle missing seconds (from sensor dropouts) gracefully rather than erroring.
5. **PDF generation** — select library/approach for generating the client-facing session plan PDF at each phase transition.
6. **Zone-feedback timing edge case** — implement the special-case 2-checks-per-50-sec rule for Shape phase HIIT runs, distinct from the standard 15-sec cycle used elsewhere.
7. **Firestore/data schema** — extend as needed to track phase (Foundation/Level Up/Shape/Maintain), each phase's independent session counter, Option A/B daily selection, and muscle-group priority per session.

---

## OPEN PRODUCT DECISIONS (NOT YET RESOLVED)

1. **Phase 4 (Maintain)** — entirely undesigned; planned for future work.
2. **Privacy policy** — not required now (healthy-subjects-only); revisit if program expands to diagnosed conditions.
3. **Shape HIIT's 10-sec overage (35:10 vs. 35:00)** — confirmed acceptable as-is, no trim needed.
