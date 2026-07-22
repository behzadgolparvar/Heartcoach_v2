# Functional Design Plan — Unit 3: iPhone Workout Engine

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
- [x] `aidlc-docs/construction/unit3-workout-engine/functional-design/domain-entities.md`
- [x] `aidlc-docs/construction/unit3-workout-engine/functional-design/business-logic-model.md`
- [x] `aidlc-docs/construction/unit3-workout-engine/functional-design/business-rules.md`
- [x] `aidlc-docs/construction/unit3-workout-engine/functional-design/frontend-components.md`

## Stories Covered
US-06 (Select workout), US-07 (Start workout), US-08 (Zone coaching),
US-09 (Positive feedback), US-10 (Safety alert), US-11 (Emergency stop),
US-12 (Pause/Resume), US-13 (End workout), US-15 (Voice coaching),
US-16 (Post-workout summary), US-17 (Session saved), US-18 (History list)

---

## Context Summary

Unit 3 is the heart of the app — the real-time coaching engine. It receives live HR from the Watch via WatchConnectivity (Unit 4 sends it), runs 3-layer coaching logic, drives voice output and haptics, manages the workout session lifecycle, and saves the completed session. This is the most complex unit.

Questions below target the 5 genuine ambiguities not resolved by the brief or application design.

---

## Functional Design Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
How should the workout be selected before starting?

A) **Pre-selected from Home** — the user's `preferredWorkout` (set in onboarding/settings) is used automatically. The Start Workout button starts that program. A small picker on the Home screen or a pre-start screen lets the user switch.
B) **Dedicated selection screen** — tapping Start Workout always shows a selection screen where the user explicitly picks Continuous, HIIT, or Fartlek before each workout, regardless of their preferred workout setting.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
What should the workout screen show during a recovery phase (when there's no target zone)?

A) **"Recovery" label + current HR + phase countdown** — no zone coaching, just show what the current HR is and how long the recovery phase lasts. A subtle instruction like "Walk it out" is displayed.
B) **Hide HR zone indicator entirely** — during recovery, the zone ring/bar disappears. Only the phase instruction and countdown are shown.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 3
When should voice coaching speak?

A) **Always use voice** — voice coaching fires for all Layer 2 messages ("Speed up", "Slow down") and Layer 3 positive feedback ("Great work, keep going") via AVSpeechSynthesizer. User can mute in Settings.
B) **Only when AirPods/headphones are detected** — voice coaching activates only if an audio output device is connected. Falls back to haptics + on-screen text only when no headphones are present.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 4
What happens when the user pauses the workout?

A) **Full pause** — timer stops, HR collection stops (Watch pauses workout session), coaching engine freezes. Resume restarts everything from where it left off.
B) **Soft pause** — timer stops and coaching freezes, but Watch continues collecting HR in the background (so the HR stream is complete). Resume restarts the timer and coaching.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 5
What should the post-workout summary screen show?

A) **Minimal summary** — total duration, average HR, and a simple time-in-zones bar. Tapping "Done" saves and goes to Home.
B) **Detailed summary** — total duration, average HR, time-in-zones bar with zone breakdown (minutes per zone), max HR reached, and the workout type. Tapping "Done" saves and goes to Home.
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

Please fill in all answers and let me know when you're done.
