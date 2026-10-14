# Phase 4 — Level Up · Functional Design Plan

**Scope (v5 re-plan):** the **Level Up** training stage (stage 2) — aerobic Continuous/HIIT **with bodyweight leg-exercise phases woven in**, its own 60-session counter, and its own unlock questions.
- Level Up **Continuous**: 7 blocks × 5:00; Blocks 1–6 run ~3:50 then an exercise phase then walk to 5:00; Block 7 pure run (§2.1)
- Level Up **HIIT**: warm-up (3:00) + post-warmup exercise block (3:00–5:00) + **10 rounds × 3:00** (1:00 run → walk+exercise 20 reps → walk) (§2.2) — **structurally different from Foundation HIIT**
- Leg-exercise bank (§G) with bilateral/unilateral timing (§2.1)
- Injury/comfort **exclusion** (§E Level Up unlock) feeding exercise selection
- Reuse P3 progression (same §B framework, Level Up's own counter) + advance Foundation→Level Up (replaces P3's "coming soon")

**Spec source:** `hr-coaching-app-full-spec.md` §Phase 2 (lines 57–108), §E (291–295), §G (325–326). **Inputs:** P1b `jointIssues`/`healthHistory`; P2 protocol/coaching/cooldown/scoring; P3 `ProgressionEngine` + `ProgramState`.
**Not in Phase 4:** Shape (P5), milestones/reminders/export/PDF (P6). Maintain out of scope.

## Design steps (tracked)
- [x] Leg-exercise bank + metadata (bilateral/unilateral, joint-impact tags)
- [x] Level Up protocol builder (Continuous w/ internal timeline; reworked HIIT) + new exercise phase kind
- [x] Exercise selection + exclusion engine (random rotation, injury/comfort filtering)
- [x] Level Up unlock question flow + storage
- [x] Coaching for exercise phases (intro + synced rep count + walk/next-phase cues)
- [x] Stage advancement Foundation→Level Up; domain entities + business rules

---

## Question 1 — Leg-exercise bank contents & size
§Phase 2 line 59 says "20+ standing bodyweight leg exercises"; §G lists **8** plyometric exercises ("Bank of 8+; rotate 6+ per session"). These conflict.

A) **Use the §G list of 8** (squat jumps, jumping lunges, lateral bounds, step-up jumps, skater jumps, jump rope/phantom, broad jumps, split squat jumps) as the bank now; flag the "20+" number to the collaborator as a content-expansion item (recommended)
B) Author ~20 exercises now to hit the line-59 number
X) Other (describe after [Answer]:)

[Answer]: A

## Question 2 — Exercise selection (randomness + variety)
"Type per block: fully random from the bank" + "rotate 6+ per session."

A) **Seeded random per session, no-repeat-until-pool-cycled** — reproducible for tests, guarantees variety within a session (recommended)
B) Pure random each pick (may repeat within a session)
X) Other (describe after [Answer]:)

[Answer]: A

## Question 3 — Bilateral vs unilateral timing + per-exercise classification
§2.1: Bilateral = 30s/15 reps; Unilateral = 32s/8 reps per leg. Each bank exercise is one or the other.

A) **Tag each exercise `bilateral`/`unilateral` in the bank** (I'll assign sensible defaults — e.g. squat jumps/lateral bounds/broad jumps/jump rope = bilateral; jumping lunges/step-up jumps/skater jumps/split squat jumps = unilateral) and drive timing/reps from the tag (recommended)
B) Treat all as bilateral (30s/15) for now
X) Other (describe after [Answer]:)

[Answer]: A

## Question 4 — Injury/comfort exclusion model (§E unlock)
Unlock Q1 (injury → exclude high-impact for that joint) + Q2 (not comfortable → user pre-selects an approved subset).

A) **Tag each exercise with impacted joints** (knee/hip/ankle) + an impact level; exclude exercises matching a reported injured joint; if Q2 = "not comfortable", intersect with the user's pre-approved subset. Selection draws only from the surviving set (recommended)
B) Injury → show a blanket caution but don't actually exclude; rely on Q2 subset only
X) Other (describe after [Answer]:)

[Answer]: A

## Question 5 — Level Up unlock questions: source & re-use of P1b data
P1b already captured `jointIssues`. §E asks the injury question again "entering Phase 2."

A) **Ask the §E unlock set once at Level Up entry, pre-filled from P1b `jointIssues`** (user confirms/edits); store the Level Up answers (injured joints + comfort subset) on the profile (recommended)
B) Skip re-asking — derive exclusions purely from P1b `jointIssues`
C) Ask fresh, ignore P1b
X) Other (describe after [Answer]:)

[Answer]: A

## Question 6 — Protocol model for exercise phases
Foundation's `PhaseKind` has no exercise segment.

A) **Add `PhaseKind.exercise`** (not HR-scored; carries an assigned `LegExercise` + rep target) and build the Level Up timelines as `FoundationProtocol`s with run/exercise/walk phases; scoring still counts only `warmup/block/work` run phases (recommended)
B) Model exercises outside the protocol timeline (parallel track)
X) Other (describe after [Answer]:)

[Answer]: A

## Question 7 — Level Up HIIT structure (reworked)
Foundation HIIT = 15×(1/1). Level Up HIIT (§2.2) = warm-up 3:00 + exercise block 3:00–5:00 + **10 rounds × 3:00** (1:00 run / walk+exercise/ walk).

A) **Build Level Up HIIT per the §2.2 table** (its own 10-round timeline with embedded exercises), separate from Foundation's builder; run portions (warm-up + each round's 1:00 run) are the scored phases (recommended)
B) Keep Foundation's 15×1/1 and just add exercises
X) Other (describe after [Answer]:)

[Answer]: A

## Question 8 — Coaching for exercise phases
During an exercise phase: intro/visualization talk, **synced rep count**, "announce slow walk", "announce next phase" (§2.1 timeline).

A) **Extend the session driver with an exercise-cue layer** (deterministic, timeline-driven cues incl. a synced rep countdown) while reusing CoachingEngine v2 for the run phases (recommended)
B) Reuse only CoachingEngine v2 (no synced rep count)
X) Other (describe after [Answer]:)

[Answer]: A

## Question 9 — Foundation→Level Up advancement
P3 currently shows "Foundation complete — Level Up coming soon" at 60.

A) **On Foundation completion, present the Level Up unlock (Q5); on completion set `currentStage = .levelUp` + init its `StageProgress` at 0**; Home then assigns Level Up sessions. Classification carries over unchanged (recommended)
B) Require a manual "Start Level Up" tap with no unlock questions
X) Other (describe after [Answer]:)

[Answer]: A

---

### After answers
I'll generate the functional-design artifacts under `aidlc-docs/construction/phase4-levelup/functional-design/` (business-logic-model, business-rules, domain-entities), then present the 2-option completion gate.
