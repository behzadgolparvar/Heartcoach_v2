# Functional Design Plan — Unit 2: iPhone Foundation

## Execution Checklist

- [x] Step 1: Analyze unit context
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers — no ambiguities
- [x] Step 6: Generate functional design artifacts
- [ ] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit2-iphone-foundation/functional-design/domain-entities.md`
- [x] `aidlc-docs/construction/unit2-iphone-foundation/functional-design/business-logic-model.md`
- [x] `aidlc-docs/construction/unit2-iphone-foundation/functional-design/business-rules.md`
- [x] `aidlc-docs/construction/unit2-iphone-foundation/functional-design/frontend-components.md`

## Stories Covered
US-01 (Sign in), US-02 (Profile), US-03 (Goal/Workout), US-04 (View Zones),
US-05 (Zones Recalculate), US-19 (Update Profile), US-20 (Update Goal)

---

## Context Summary

Unit 2 builds the app shell — authentication, onboarding, home screen, settings, and zone display. It imports `HeartRateCoachCore` for all domain models. The questions below target 5 genuine design decisions not yet answered by the brief or application design.

---

## Functional Design Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
What should the onboarding flow look like?

A) **Single screen** — all fields (age, RHR, sex, weight, goal, preferred workout) on one scrollable form; user fills in and taps "Continue"
B) **Multi-step wizard** — separate screens for each group: (1) physiological data: age + RHR, (2) optional details: sex + weight, (3) preferences: goal + workout type; each step has a "Next" button
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

### Question 2
What is the main navigation structure of the iPhone app?

A) **Tab bar** — bottom tabs for Home, History, Settings; persistent navigation visible at all times
B) **NavigationStack from Home** — Home is the root; History and Settings are pushed as detail screens; no persistent tab bar
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 3
When should HealthKit authorization be requested from the user?

A) **During onboarding** — request HealthKit HR permission on the onboarding screen alongside the RHR guidance text (user sees why it's needed in context)
B) **Lazily when the first workout starts** — request permission only when the user taps "Start Workout" for the first time (avoids asking for permissions before the user understands the app)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 4
When should profile data be written to Firestore?

A) **On explicit Save** — user edits fields then taps a "Save" button; Firestore write happens on button tap (one write per save action)
B) **Auto-save on change** — Firestore is updated whenever a field value changes (no Save button needed; changes persist automatically)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 5
What should the Home screen show while the user has no previous sessions yet (first time after onboarding)?

A) **Empty state message** — "No sessions yet. Start your first workout!" with a prominent Start button
B) **Zone summary card** — show the user's personalised HR zones as the primary content until the first session exists
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

Please fill in all answers and let me know when you're done.
