# NFR Requirements Plan — Unit 4: Apple Watch App

## Execution Checklist

- [x] Step 1: Assess NFR categories
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers
- [x] Step 6: Generate NFR artifacts
- [x] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit4-apple-watch/nfr-requirements/nfr-requirements.md`
- [x] `aidlc-docs/construction/unit4-apple-watch/nfr-requirements/tech-stack-decisions.md`

---

## NFR Category Assessment

| Category | Applicable | Notes |
|---|---|---|
| Performance | Yes | HR delivery latency, haptic timing |
| Reliability | Yes | HKWorkoutSession background continuity, WCSession gaps |
| Security | Yes | HR data on Watch — SECURITY-03 extends here |
| Scalability | N/A | Single user, single session, on-device |
| Availability | Yes | Background execution while screen off |
| Maintainability | Minimal | Thin Watch app; PBT not applicable (only ZoneCalculator + CoachingEngine) |

Most NFR patterns carry directly from prior decisions:
- WCSession fire-and-forget (Unit 3 NFR)
- No HR data in logs (SECURITY-03, Unit 2)
- HR staleness handled on iPhone (Unit 3 NFR)

One genuine question remains about HealthKit data persistence on Watch.

---

## NFR Requirements Question

Please fill in the letter after the `[Answer]:` tag.

---

### Question 1
When the `HKWorkoutSession` ends on the Watch, `HKLiveWorkoutBuilder` can either save the workout data (HR samples, duration) to the user's Apple Health app, or discard it.

A) **Save to Apple Health** — the completed workout appears in the user's Apple Health app and is visible to other apps (Strava, Fitness+, etc.) that read HealthKit workouts. The user gets a persistent workout record even if Firebase sync fails.

B) **Discard** — `builder.discardWorkout()` is called on session end. The workout record exists only in HeartCoach's Firebase database. Avoids a duplicate entry when users check Apple Health (they'd see both a HeartCoach workout and a raw HR recording from the Watch).

[Answer]: A

---

Please fill in your answer and let me know when you're done.
