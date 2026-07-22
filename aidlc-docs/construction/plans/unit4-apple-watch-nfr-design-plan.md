# NFR Design Plan — Unit 4: Apple Watch App

## Execution Checklist

- [x] Step 1: Analyze NFR requirements
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers
- [x] Step 6: Generate NFR design artifacts
- [x] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit4-apple-watch/nfr-design/nfr-design-patterns.md`
- [x] `aidlc-docs/construction/unit4-apple-watch/nfr-design/logical-components.md`

---

## Context Summary

Most Unit 4 NFR patterns are already determined:
- WCSession fire-and-forget (Unit 3 decision) ✓
- Haptic mapping: HapticPattern → WKHapticType (Q4 — A) ✓
- HealthKit save on session end: `builder.finishWorkout()` (Q1 — A) ✓
- Thread model: WCSession + HealthKit callbacks dispatch to @MainActor ✓
- No new dependencies: HealthKit, WatchKit, WatchConnectivity are system frameworks ✓

One genuine design decision remains: what happens if the Watch app is suspended or crashes while a workout is in progress.

---

## NFR Design Question

Please fill in the letter after the `[Answer]:` tag.

---

### Question 1
If the Watch app is suspended by watchOS during an active workout (screen off for a long time, OS memory pressure), `HKWorkoutSession` keeps the HR sensor running in the background. But when the app is next activated, should it attempt to reconnect to that session?

A) **Recover the session** — on app launch, call `HKHealthStore().recoverActiveWorkoutSession(completion:)`. If an active session is found, reconnect `HRService` to it and resume HR streaming. The user's workout continues uninterrupted on the iPhone even if the Watch app was briefly suspended.

B) **No recovery** — if the app is suspended, treat it as if the Watch disconnected. The iPhone's staleness tracker handles the HR gap (≥15s triggers Layer 1 "no signal"). When the user next activates the Watch, `IdleWatchView` is shown; the workout continues on iPhone if the user resumes from there.

[Answer]: A

---

Please fill in your answer and let me know when you're done.
