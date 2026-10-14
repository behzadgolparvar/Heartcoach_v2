# Phase 5 — Shape · Functional Design Plan

**Scope (v5 re-plan):** the **Shape** training stage (stage 3) — daily **Option A/B** choice, per-session muscle-group selection + ranking, weight-training banks, the Legs rule, and the special Shape-HIIT coaching cadence.
- **Option A** (outdoor/no-equipment): plyometric leg exercises, 20 reps/min (reuses the P4 leg bank)
- **Option B** (treadmill + weights): client picks & ranks **exactly 2 muscle groups** (priority + secondary) per session; 30-rep weight exercises
- **Legs rule:** if Legs is one of the 2 groups in Option B, Legs phases use plyometric (leg bank), the other muscle uses weights (§Phase3)
- **Continuous §3.1:** 7 blocks (Block 1 = 6:00; Blocks 2–6 shortened run + 2:10 exercise; Block 7 pure run); 6 exercise phases, **4-2 split** (priority 4, secondary 2)
- **HIIT §3.2:** warm-up + Exercise Phase 0 + 10 rounds (0:50 run + 2:10 exercise); **11 exercise phases**, **6-5 split**; **2 zone checks per 50-sec run** (special cadence)
- Shape unlock (§E) + per-session equipment/focus re-ask; advance Level Up→Shape

**Spec source:** `hr-coaching-app-full-spec.md` §Phase 3 (112–206), §E (297–302), §G (328–341). **Inputs:** P4 leg bank + `ExerciseSelector` + unlock/exclusion; P2 coaching/cooldown/scoring; P3 progression; P1b `MuscleGroup`/`ShapeOption` placeholders.
**Not in Phase 5:** milestones/reminders/export/PDF (P6), Maintain.

## Design steps (tracked)
- [x] Weight-exercise banks (§G, 5 muscle groups × 6) + muscle-group model
- [x] Shape unlock + per-session Option A/B + muscle selection/ranking
- [x] Shape protocol builder (Continuous §3.1 + HIIT §3.2) with 4-2 / 6-5 alternation + Legs rule
- [x] Shape-HIIT special coaching cadence (2 checks / 50-sec run)
- [x] Advance Level Up→Shape; domain entities + business rules

---

## Question 1 — Option A/B daily choice: where & when
"Daily choice (every session, not locked once)."

A) **Ask at session start, every session** (a pre-session Option A/B screen, defaulting to the Shape-unlock equipment preference); remember last choice as the default (recommended)
B) Set once at unlock, changeable only in settings
X) Other (describe after [Answer]:)

[Answer]: A

## Question 2 — Muscle-group selection + ranking (Option B)
"Client selects & ranks exactly 2 muscle groups per session (priority + secondary)."

A) **Per-session picker: choose exactly 2 of {chest, back, shoulders, arms, abs, legs} and order them (priority, secondary)**, pre-filled from the Shape-unlock focus areas; validation enforces exactly 2 (recommended)
B) Pick 2 once at unlock, fixed for the stage
X) Other (describe after [Answer]:)

[Answer]: A

## Question 3 — Weight-exercise banks (§G)
§G lists 6 exercises each for chest/back/shoulders/arms/abs (standing free-weight).

A) **Author the 5 banks from §G verbatim (6 each)**; `WeightExercise { id, name, muscle }`; 30 reps, ~2s/rep (~60s); legs uses the P4 plyometric bank instead (Legs rule) (recommended)
B) Fewer/placeholder exercises for now
X) Other (describe after [Answer]:)

[Answer]: A

## Question 4 — Legs rule (Option B)
"If Legs is chosen (priority or secondary), Legs' phases use plyometric; the other chosen muscle uses weight training."

A) **Per phase, pick the exercise by that phase's assigned muscle**: if the muscle is `legs` → draw from the plyometric leg bank (20 reps); else → draw from that muscle's weight bank (30 reps). A session mixes both types (recommended)
B) Disallow Legs as a selectable muscle in Option B
X) Other (describe after [Answer]:)

[Answer]: A

## Question 5 — Exercise-phase alternation (4-2 and 6-5)
Continuous (6 phases): priority gets phases 1,3,5,6; secondary 2,4. HIIT (11 phases, 0–10): priority gets even (0,2,4,6,8,10 = 6), secondary odd (1,3,5,7,9 = 5).

A) **Encode both patterns deterministically** from the spec tables, mapping each phase index → priority/secondary → that muscle's exercise (recommended)
B) Simple strict alternation (ignore the 4-2 extra-priority detail)
X) Other (describe after [Answer]:)

[Answer]: A

## Question 6 — Option A (no-equipment) content
"Option A — plyometric leg exercises, 20 reps/min."

A) **Reuse the P4 leg bank + `ExerciseSelector`** (seeded no-repeat, injury-excluded via the Shape unlock); every exercise phase is a plyometric leg move, 20 reps (recommended)
B) A separate Option A bank
X) Other (describe after [Answer]:)

[Answer]: A

## Question 7 — Shape protocol builder & exercise-phase model
Shape timelines differ from Level Up (Block 1 = 6:00; 2:10 exercise phases; HIIT Exercise Phase 0 + 11 phases).

A) **New `ShapeProtocolBuilder`** producing `FoundationProtocol`s with run/exercise/rest-walk phases per §3.1/§3.2; reuse `PhaseKind.exercise` (carry muscle + reps + plyo/weight); each exercise phase = talk+exercise(60s)+rest+walk folded into an `.exercise` (60s) + `.rest` walk, talk/rest as cues (recommended)
B) Extend `LevelUpProtocolBuilder`
X) Other (describe after [Answer]:)

[Answer]: A

## Question 8 — Shape-HIIT special coaching cadence
"Zone feedback in 50-sec runs: 2 checks per run segment (not the standard 15-sec cycle)."

A) **For Shape-HIIT run phases, drive the coaching tick at ~25-sec spacing (2 checks per 50-sec run)** instead of 15s; Continuous keeps 15s; safety stays 5s (recommended)
B) Keep 15s everywhere (ignore the special case)
X) Other (describe after [Answer]:)

[Answer]: A — 2 zone checks per 50-sec Shape-HIIT run, placed at ~15s and ~40s (skip 0s: HR lags the run start after the preceding walk/exercise; last check ~10s before the run ends so there's time to correct). Shape Continuous keeps 15s; safety stays 5s. Exact offsets are a device-tuning detail for Build & Test; the coaching engine logic is unchanged — only the tick cadence differs.

## Question 9 — Shape unlock (§E) + per-session re-ask
§E: Q1 equipment pref (sets default Option), Q2 pain during Level Up (safety), Q3 focus areas (primes muscle selection). Q1/Q3 also asked per session.

A) **Unlock once at Shape entry** (store equipment-pref default + focus areas + a Level-Up-pain safety acknowledgement); Option A/B (Q1) and muscle selection (Q3) then default from it but are chosen **each session** (Q1/Q2) (recommended)
B) Unlock only; no per-session re-ask
X) Other (describe after [Answer]:)

[Answer]: A

## Question 10 — Level Up → Shape advancement
Mirrors P4's Foundation→Level Up.

A) **At Level Up 60, present the Shape unlock; on completion set `currentStage = .shape` + fresh `StageProgress`**; Home then runs Shape sessions. Classification carries over (recommended)
B) Manual start, no unlock
X) Other (describe after [Answer]:)

[Answer]: A

---

### After answers
I'll generate the functional-design artifacts under `aidlc-docs/construction/phase5-shape/functional-design/` (business-logic-model, business-rules, domain-entities), then present the 2-option completion gate.
