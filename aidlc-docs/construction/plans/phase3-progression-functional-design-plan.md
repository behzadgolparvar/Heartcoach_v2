# Phase 3 — Progression & Assignment · Functional Design Plan

**Scope (v5 re-plan):** the headline engine that **assigns today's Foundation session** and advances the user through the stage.
- Ratio progression (§B): 60 sessions / 3 sub-phases of 20, ratio by experience × mentality (× goal for Beginner)
- "Today's session" assignment from the ratio → replaces the manual picker (manual override optional)
- Progression advancement (when a session counts)
- Relapse / re-entry push-back (§C)
- Non-negotiable 15-min walk minimum (§I) — resets relapse clock, doesn't count
- Stage completion → advance toward Level Up (P4 gate)

**Spec source:** `hr-coaching-app-full-spec.md` §B, §C, §I. **Inputs from earlier phases:** `resolvedExperience`, `mentalityLean`, `goals` (P1b); `ProgramState`/`StageProgress` (P1b); Foundation protocols + `sessionFlag`/`cooldownSkipped`/scoring (P2).
**Not in Phase 3:** Level Up exercises (P4), Shape (P5), milestones/reminders/PDF (P6). Maintain out of scope.

## Design steps (tracked)
- [x] Ratio tables (§B) as pure data (Beginner-FWL / Beginner-routine-cardio / Intermediate / Advanced × mentality × sub-phase)
- [x] `ProgressionEngine`: resolve ratio → assign today's session type; advancement rules
- [x] Relapse/re-entry push-back + non-negotiable minimum
- [x] Data additions (last-session date, assignment bookkeeping) + Home integration
- [x] Domain entities + business rules

---

## Question 1 — Turning a ratio into today's session type
Ratios are **HIIT:Continuous** per sub-phase (e.g. Beginner-FWL/Outcome SubPhase1 = 1:2). We need a deterministic rule that maps "session N within the sub-phase" → Continuous or HIIT.

A) **Deterministic repeating pattern** per sub-phase: expand the ratio into a fixed cycle (e.g. 1:2 → `HIIT, Cont, Cont, HIIT, Cont, Cont, …`) and index by session number — reproducible, even spacing, no RNG (recommended)
B) **Cumulative-proportion** rule: pick whichever type keeps the running HIIT:Cont proportion closest to the target ratio
C) **Seeded random** draw weighted by the ratio
X) Other (describe after [Answer]:)

[Answer]: A

## Question 2 — Beginner goal resolution (which table)
Beginner uses a **Fast-Weight-Loss** table or the **Routine/Cardio** rule. `goals` is a multi-select set.

A) **Fast-Weight-Loss table if `goals` contains `fastWeightLoss`**, otherwise Routine/Cardio (weight-loss intent dominates) (recommended)
B) Use Routine/Cardio unless `fastWeightLoss` is the *only* goal
C) Ask the user to pick a primary goal at onboarding
X) Other (describe after [Answer]:)

[Answer]: A

## Question 3 — Beginner Routine/Cardio representation
Spec: "Continuous only (occasional HIIT ~1-in-4 if outcome-focused)."

A) **Continuous every session**, except **outcome-lean** users get **HIIT every 4th session** (1-in-4); process/mixed = pure Continuous (recommended)
B) Pure Continuous for all Beginner routine/cardio regardless of mentality
X) Other (describe after [Answer]:)

[Answer]: A

## Question 4 — When a session counts toward progression
Advancement increments `StageProgress.sessionsCompleted`.

A) **Count only a completed, scored training session** of the assigned/known type (`sessionFlag` = continuous/hiit); **exclude** `walk_fallback` and the non-negotiable minimum, and exclude <20-min discards (§J). `cooldownSkipped` still counts (training was done) (recommended)
B) Count any started session
C) Count only sessions at/above a score tier
X) Other (describe after [Answer]:)

[Answer]: A

## Question 5 — Relapse push-back semantics (§C)
Gap since last counted session → 2w: −3, 3w: −5, 1mo: −8, >1mo: reset. Push-back decrements `sessionsCompleted`.

A) **Clamp at the current sub-phase's start** — push-back never drops below the sub-phase you're in; ">1 month" = reset to the **start of the current sub-phase** (recommended)
B) Allow push-back across sub-phase boundaries (can fall into an earlier sub-phase); ">1 month" = reset to **session 0** of the stage
C) ">1 month" = reset to session 0; smaller gaps clamp at current sub-phase start
X) Other (describe after [Answer]:)

[Answer]: B

## Question 6 — When push-back is evaluated, and the date it uses
Push-back needs the gap since the last counted session.

A) **Store `lastCountedSessionDate` in `ProgramState`**; evaluate the gap when the user opens the app / starts a session, apply once per gap, log it positively (recommended)
B) Compute from session history each time (no new stored field)
X) Other (describe after [Answer]:)

[Answer]: A

## Question 7 — Non-negotiable minimum (§I) — trigger & effects
15-min walk (8 fast / 7 slow), low-motivation fallback.

A) **User-initiated** from Home ("Not feeling it today? Do the 15-min minimum"): runs a simple timed walk, logged with its own flag, **resets the relapse clock** (updates `lastCountedSessionDate`) but **does not** increment `sessionsCompleted` (recommended)
B) Auto-offered only after a detected gap
C) Both: user-initiatable and auto-offered after a gap
X) Other (describe after [Answer]:)

[Answer]: A

## Question 8 — Foundation completion (P4 not built yet)
At 60 counted sessions the stage is complete, but Level Up (P4) doesn't exist yet.

A) **Show a "Foundation complete 🎉 — Level Up coming soon" state** and keep letting the user run Foundation sessions (assignment stays at Sub-Phase 3 ratios) without further advancement (recommended)
B) Loop back to Sub-Phase 1
C) Hard stop — no more sessions until P4 ships
X) Other (describe after [Answer]:)

[Answer]: A

## Question 9 — Home / workout entry integration
P2 uses a manual picker. P3 assigns today's session.

A) **Home shows "Today's session: <type>"** with a primary Start button; keep a secondary "Choose a different workout" manual override (recommended)
B) Replace the picker entirely — assigned session only, no override
X) Other (describe after [Answer]:)

[Answer]: A

---

### After answers
I'll generate the functional-design artifacts under `aidlc-docs/construction/phase3-progression/functional-design/` (business-logic-model, business-rules, domain-entities), then present the 2-option completion gate.
