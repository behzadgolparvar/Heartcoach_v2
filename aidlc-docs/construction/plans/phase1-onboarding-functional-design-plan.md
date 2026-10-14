# Phase 1 — Onboarding & Data Model · Functional Design Plan

Design decisions for Phase 1. Most of the form is fully specified; these are the choices that materially affect the **data model, migration, and onboarding flow**. Answer each after `[Answer]:` (pick "Other" to write your own).

## Design steps (tracked)
- [ ] Domain entities (Profile, Physiology, HRZones, Settings, Consent, Schedule)
- [ ] Onboarding form component hierarchy + per-section validation
- [ ] Business rules (units conversion, BMI, RHR/MaxHR, required-field gating, consent)
- [ ] v1→v2 data migration mapping
- [ ] Firestore schema mapping (per full-spec §5.1)

---

## Question 1 — Existing v1 users (migration)
Current testers already have a v1 profile (age, RHR, sex, weight, goal, preferredWorkout). v2 onboarding asks for much more.

A) **Smart migration** — map v1 fields into the new schema and, on next launch, ask only for the **new** fields (experience, mentality, goals-multi, height, scheduling, consent) — no re-typing what we already have (recommended)
B) **Full re-onboarding** — everyone completes the new form from scratch
C) **Opt-in** — v1 users keep the v1 experience until they choose to switch to v2
X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 2 — Deriving "mentality lean" from the 3 questions
The assignment engine (§2.3) needs an overall lean: **Outcome-focused / Process-focused / Mixed**. The 3 mentality questions are each binary (process↔outcome, habit↔goal, fixed↔variety).

A) **Majority rule** — map each answer to outcome-ish or process-ish; 2–3 one way → that lean; otherwise **Mixed** (recommended)
B) **Primary question only** — use just the motivation-driver question (process vs outcome); the other two inform coaching tone only
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3 — Required vs optional fields to finish onboarding
Which fields **block** completing onboarding vs. are skippable?

A) **Required:** consent, age, gender, RHR, goals, fitness experience, the 3 mentality questions, session length + frequency. **Optional:** height/weight/BMI, all health-history (conditions, meds, smoking, joint, Ozempic, occupation), equipment, device, preferred days/time (recommended)
B) **Minimal required:** consent, age, RHR only — everything else optional (fastest signup, but assignment engine may lack inputs)
C) **Everything required** — no optional fields
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4 — Default units (weight/height)
The user can toggle, but what's the default before they touch it?

A) **Detect from device locale** (US → lbs/in, elsewhere → kg/cm) (recommended)
B) Default **metric** (kg/cm)
C) Default **imperial** (lbs/in)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5 — Resting HR entry
Spec says "guided from Apple Health, morning value."

A) **Auto-fetch from HealthKit and pre-fill**, editable, with the 40–100 confirm-warning (reuses v1's resting-HR fetch) (recommended)
B) **Manual entry only** (no auto-fetch)
X) Other (please describe after [Answer]: tag below)

[Answer]: A
