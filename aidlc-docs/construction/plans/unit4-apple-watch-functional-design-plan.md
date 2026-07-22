# Functional Design Plan — Unit 4: Apple Watch App

## Execution Checklist

- [x] Step 1: Assess if Functional Design is needed (YES — new Watch target)
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers
- [x] Step 6: Generate functional design artifacts
- [x] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit4-apple-watch/functional-design/domain-entities.md`
- [x] `aidlc-docs/construction/unit4-apple-watch/functional-design/business-logic-model.md`
- [x] `aidlc-docs/construction/unit4-apple-watch/functional-design/frontend-components.md`

---

## Context Summary

Unit 4 is the Apple Watch companion app. Its role is narrow and well-defined:
- **Sense**: Read live HR from the Watch's optical sensor
- **Stream**: Send HR readings to iPhone every ~5 seconds via WCSession
- **Execute**: Receive haptic commands from iPhone and fire them immediately
- **Display**: Show a simple workout status screen while a workout is active

The iPhone (Unit 3) owns all coaching logic. The Watch is a sensor + haptic actuator + status display.

Already determined from prior units:
- HR message format: `["hr": bpm]` (WatchBridge.swift decodes this)
- Haptic message format: `["haptic": pattern.rawValue]` (HapticPattern is now String-typed)
- HeartRateCoachCore SPM package is reused by Watch target (CoachingMessage, HapticPattern, HRReading, etc.)

---

## Functional Design Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
How should the Watch collect heart rate from the sensor?

A) **HKWorkoutSession + HKLiveWorkoutBuilder** — starts an active workout session on Watch when iPhone begins a workout. This keeps the HR sensor sampling every ~5 seconds throughout the workout, even when the Watch display is off. Required for continuous background HR. This is the standard Apple Watch workout app pattern.

B) **HKAnchoredObjectQuery** — periodically queries saved HealthKit samples. Simpler to implement but unreliable during background execution and not designed for real-time streaming. Not recommended for a workout coaching app.

[Answer]: A

---

### Question 2
What should the Apple Watch screen display during an active workout?

A) **Full status** — current HR (large, zone-colored), zone number, phase name (e.g. "Exercise"), last coaching message text (small, at bottom). Best for users who glance at their Watch while running.

B) **Minimal** — only current HR (large) and zone number. Cleaner; fewer distractions while running.

[Answer]: A

---

### Question 3
What does the Watch show when no workout is active (idle state)?

A) **Waiting screen** — HeartCoach logo + "Start workout on iPhone". Watch is a companion; the workout always starts from the iPhone.

B) **Last session summary** — shows avg HR and duration from the most recent completed workout. Requires Watch to receive session summary from iPhone after workout ends.

[Answer]: A

---

### Question 4
How should `HapticPattern` values be mapped to watchOS haptic types?

A) **Direct mapping**:
   - `short` → `WKHapticType.notification`
   - `long` → `WKHapticType.directionUp`
   - `doubleTap` → `WKHapticType.success`
   - `emergencyRepeated` → `WKHapticType.retry` (strongest available)

B) **Custom mapping** — describe your preferred mapping after `[Answer]:`.

[Answer]: A

---

Please fill in your answers and let me know when you're done.
