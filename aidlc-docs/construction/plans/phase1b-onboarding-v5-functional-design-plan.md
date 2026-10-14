# Phase 1b — Onboarding v5 Deltas · Functional Design Plan

**Unit:** Onboarding v5 deltas · **Type:** brownfield (extend the shipped Phase 1 onboarding/profile) · **Branch:** new_design_Sep_2026
**Spec source:** `hr-coaching-app-full-spec.md` §A (Experience Classification), §§on Ozempic/GLP-1; `v2-requirements.md` v5 revision.
**Scope:** data-model + onboarding-logic changes only. No protocol/coaching work (that's P2). Keep the app building and v1 workout flow runnable.

## What already exists (Phase 1, shipped)
- `UserProfileV2.fitnessExperience: FitnessExperience` (single enum: beginner/intermediate/advanced)
- `HealthHistory.onAntiObesityTherapy: Bool`, `hrMedications: Set<HRMedication>`, joint issues
- No `trainingStage`, no per-stage session counter, no Option A/B or muscle-priority fields

## v5 classification rules (from spec §A, authoritative)
- **Q1 (authoritative):** training-history duration → Beginner (never / 1+ yr gap) / Intermediate (<1 yr consistent, or recent return) / Advanced (1+ yr consistent). Honesty-framing prompt.
- **Q2 (self-select, independent):** same three tiers w/ plain-language defs, Q1's result hidden.
- **Resolution matrix:** (B,A)→Intermediate, (A,B)→Intermediate (both logged as mismatch override); any other combo → **Q1 wins**.
- **Ozempic/GLP-1 "Yes" → auto-Beginner**, overrides Q1/Q2. Editable anytime; No→Yes re-triggers override + popup; Yes→No re-runs Q1/Q2. **Q1/Q2 always asked regardless** (research data).
- Classification **carries forward unchanged** across all 4 training stages — no reclassification between stages.

---

## Design steps (tracked)
- [ ] Domain: dual-experience model (`Q1Experience`, `Q2Experience`, `resolvedExperience`, `mismatchOverride` flag)
- [ ] Business rule: resolution matrix (pure function, exhaustively testable)
- [ ] Business rule: Ozempic/GLP-1 override + edit transitions (No→Yes, Yes→No)
- [ ] Domain: `TrainingStage` enum (foundation/levelUp/shape/maintain) + per-stage session counter + sub-phase index model
- [ ] Domain: Option A/B daily-selection + muscle-group-priority placeholder fields (filled in P5; shape only)
- [ ] Health/joint history → mark "active" for future (P4) exercise exclusion (no exclusion logic yet, just the data contract)
- [ ] UserProfileV2 migration/back-compat (decode old single `fitnessExperience`)
- [ ] Onboarding flow: where Q1/Q2 + Ozempic sit; popup copy from spec §A

---

## Questions (answer after each `[Answer]:`; choose "Other" to write your own)

### Question 1 — Keep or replace the existing single `fitnessExperience` field
Phase 1 stored one `fitnessExperience`. v5 needs Q1, Q2, and a resolved value.

A) **Add `q1Experience` + `q2Experience` + computed `resolvedExperience`** and keep `fitnessExperience` as a stored alias of the resolved value (back-compat for existing consumers; old profiles decode as both Q1 and resolved) (recommended)
B) **Replace** `fitnessExperience` entirely with the three new fields and update every consumer
C) Keep `fitnessExperience` as-is for resolved, add only `q1`/`q2` alongside
X) Other (describe after [Answer]:)

[Answer]: A

### Question 2 — Where `resolvedExperience` and the Ozempic override live
The resolution + override is pure logic, but the result is read all over (progression, protocols).

A) **Store the resolved value** in the profile at onboarding/edit time (write-through), with the pure resolver as the single source that computes it — read the stored field at runtime (recommended)
B) **Compute on every read** from Q1/Q2/Ozempic (never store resolved) — always consistent, but every consumer must call the resolver
X) Other (describe after [Answer]:)

[Answer]: A

### Question 3 — "Recent return" wording in Q1 (Intermediate trigger)
Spec Q1 maps "<1 yr consistent, **or recent return**" → Intermediate, and "1+ yr gap" → Beginner. The boundary between "recent return" and "1+ yr gap" needs concrete answer options for the user.

A) **Four history options:** Never trained / Trained before but stopped 1+ yr ago (→Beginner) · Returning after a break under 1 yr / under 1 yr consistent (→Intermediate) · 1+ yr consistent (→Advanced) (recommended)
B) **Free-form months-since-last + months-consistent** numeric inputs, mapped by thresholds
X) Other (describe after [Answer]:)

[Answer]: A

### Question 4 — Mismatch-override logging
The matrix logs (B,A) and (A,B) as "mismatch override … logged internally."

A) **Store a `classificationMismatch: Bool` + raw Q1/Q2 on the profile** (research field; never logged to console per SECURITY-03) (recommended)
B) Store nothing extra — resolved value only; mismatch is implicit from Q1≠Q2
X) Other (describe after [Answer]:)

[Answer]: A

### Question 5 — Ozempic source field
`HealthHistory.onAntiObesityTherapy: Bool` already exists. v5's override is specifically GLP-1/Ozempic.

A) **Reuse `onAntiObesityTherapy`** as the GLP-1 flag that drives the override (rename-free; it already means anti-obesity therapy) (recommended)
B) **Add a distinct `onGLP1Medication: Bool`** separate from the broader anti-obesity flag
X) Other (describe after [Answer]:)

[Answer]: A

### Question 6 — Training-stage/session-counter data shape
v5: each stage has its own 60-session counter + sub-phase (3×20). P1b only needs the *data contract* (P3 drives it).

A) **A `StageProgress` struct per stage** (`stage`, `sessionsCompleted`, derived `subPhase` = count/20) + `currentStage` on the profile; map of stage→progress (recommended)
B) **Flat fields** on the profile (`currentStage`, `currentStageSessions`) — simpler, but loses per-stage history
X) Other (describe after [Answer]:)

[Answer]: A

### Question 7 — Where new users start
New onboarding completes → which training stage and session count?

A) **Everyone starts at Foundation, session 0** regardless of classification (classification sets ratios, not starting stage — matches spec) (recommended)
B) Advanced/Intermediate users skip ahead to a later stage
X) Other (describe after [Answer]:)

[Answer]: A

### Question 8 — Re-onboarding / existing v2 testers
Collaborator/testers already have a Phase-1 `v2profile` in Firestore (no Q1/Q2, no stage).

A) **Decode tolerantly**: old `fitnessExperience` → both Q1 and resolved; default stage = Foundation/0; prompt them once to answer Q2 + Ozempic on next launch (no full re-onboard) (recommended)
B) **Force a full re-onboard** for anyone missing v5 fields
C) Silent migration with **no** Q2 prompt (Q2 defaults to match Q1 → no mismatch)
X) Other (describe after [Answer]:)

[Answer]: B

---

### After answers
I'll generate the functional-design artifacts under `aidlc-docs/construction/phase1b-onboarding-v5/functional-design/` (business-logic-model, business-rules, domain-entities), then present the 2-option completion gate.
