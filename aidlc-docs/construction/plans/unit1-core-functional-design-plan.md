# Functional Design Plan — Unit 1: HeartRateCoachCore

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
- [x] `aidlc-docs/construction/unit1-core/functional-design/domain-entities.md`
- [x] `aidlc-docs/construction/unit1-core/functional-design/business-logic-model.md`
- [x] `aidlc-docs/construction/unit1-core/functional-design/business-rules.md`

---

## Context Summary

Unit 1 contains pure domain logic: models, the Karvonen zone calculator, and the workout phase sequencer. The PROJECT_BRIEF.md defines the formulas and workout structures precisely. The questions below target the **5 genuine ambiguities** not yet answered by the brief.

---

## Functional Design Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
When a heart rate reading lands exactly on a zone boundary (e.g., HR = 152 and zone2.max = zone2.min of zone3 = 152), which zone should it be classified as?

A) Lower zone — boundary belongs to the zone below (e.g., HR = 152 → Zone 2 if zone2.max = 152)
B) Upper zone — boundary belongs to the zone above (e.g., HR = 152 → Zone 3 if zone3.min = 152)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
Zone boundary values from the Karvonen formula often produce decimals (e.g., zone1.min = 115.5 bpm). How should these be handled?

A) Round to nearest integer (115.5 → 116) — standard rounding
B) Floor — always round down (115.5 → 115) — makes zones slightly wider
C) Ceiling — always round up (115.5 → 116) — makes zones slightly narrower
D) Keep as floating point — no rounding, compare HR (Int) against Double boundaries
E) Other (please describe after [Answer]: tag below)

[Answer]: C

---

### Question 3
The brief specifies HR smoothing using "average of last 2–3 readings." What is the exact number of readings to average?

A) Always 2 readings (simpler, faster to respond to real changes)
B) Always 3 readings (smoother, less noise)
C) Adaptive — use however many readings are available (1 reading at start, 2 after first tick, 3 from third tick onward)
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 4
How should the session's `avg_hr` value be calculated at workout end?

A) Simple mean of all HR readings collected (sum of all HR values ÷ number of readings)
B) Time-weighted mean — each HR reading weighted by the number of seconds it was active (more accurate if readings are irregular)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 5
What happens in `WorkoutPhaseSequencer` when the final phase of the training section ends (before cool-down)?

A) Sequencer stops and emits a "workout complete" signal — cool-down is optional and user-triggered separately
B) Sequencer automatically advances to a cool-down phase (2–5 min walking + stretching prompts) as the next phase in the sequence
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in all answers and let me know when you're done.
