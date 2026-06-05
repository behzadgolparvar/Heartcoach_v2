# Unit of Work Story Map — HeartRateCoach

## Story Distribution

| Unit | Stories | Count |
|---|---|---|
| Unit 1 — HeartRateCoachCore | (no user stories — foundational layer) | 0 |
| Unit 2 — iPhone Foundation | US-01, US-02, US-03, US-04, US-05, US-19, US-20 | 7 |
| Unit 3 — iPhone Workout Engine | US-06, US-07, US-08, US-09, US-10, US-11, US-12, US-15, US-16, US-17, US-18 | 11 |
| Unit 4 — Apple Watch App | US-13, US-14 | 2 |
| **Total** | | **20** |

---

## Unit 1 — HeartRateCoachCore

No user-facing stories. Provides the domain foundation tested at code level:
- `ZoneCalculator` — covered by PBT + example-based unit tests
- `WorkoutPhaseSequencer` — covered by unit tests
- All models — covered by unit tests

---

## Unit 2 — iPhone Foundation (7 stories)

| Story ID | Title | AC Format |
|---|---|---|
| US-01 | Sign In with Apple | Bullet-points |
| US-02 | Complete My Profile | Bullet-points |
| US-03 | Set My Fitness Goal and Preferred Workout | Bullet-points |
| US-04 | View My Personalised HR Zones | Bullet-points |
| US-05 | See Zones Recalculate When I Update My Profile | Bullet-points |
| US-19 | Update My Profile and Resting HR | Bullet-points |
| US-20 | Update My Fitness Goal and Preferred Workout | Bullet-points |

**Runnable milestone**: After Unit 2 all 7 stories can be manually verified on device. Home screen is visible with stubbed Start button.

---

## Unit 3 — iPhone Workout Engine (11 stories)

| Story ID | Title | AC Format |
|---|---|---|
| US-06 | Select and Start a Workout | Bullet-points |
| US-07 | See Live Workout Data During a Session | Bullet-points (iPhone + Watch AC) |
| US-08 | Receive Coaching Cues When Out of Zone | **BDD** |
| US-09 | Receive Positive Feedback for Sustained Zone Effort | **BDD** |
| US-10 | Workout Stops Safely When HR Exceeds Maximum | **BDD** |
| US-11 | No Coaching Interruptions During Phase Transitions | **BDD** |
| US-12 | Stop a Workout Early | Bullet-points |
| US-15 | View My Session Summary After a Workout | Bullet-points |
| US-16 | Session Saved to Firebase on Workout Completion | Bullet-points |
| US-17 | Session Saved Locally When Offline, Synced Automatically | Bullet-points |
| US-18 | View My Past Sessions | Bullet-points |

**BDD stories** (US-08 through US-11) require the coaching engine to be running on a physical iPhone + Apple Watch pair. US-07 Watch AC is partially verifiable in Unit 3 (Watch app not yet built, but WatchBridge sends correct commands).

**Runnable milestone**: After Unit 3, the complete iPhone experience is functional. All 20 iPhone-side acceptance criteria are verifiable on device.

---

## Unit 4 — Apple Watch App (2 stories)

| Story ID | Title | AC Format |
|---|---|---|
| US-13 | See Coaching Overlay on Zone Transition (Watch) | Bullet-points |
| US-14 | See Emergency Stop Warning on Watch | **BDD** |

**Runnable milestone**: After Unit 4, the full system is complete. All 20 stories across both platforms can be verified end-to-end on iPhone + Apple Watch.

---

## Full Story Coverage Check

| Epic | Stories | Unit(s) |
|---|---|---|
| Authentication & Onboarding | US-01, US-02, US-03 | Unit 2 |
| HR Zone Setup | US-04, US-05 | Unit 2 |
| Workout Execution | US-06, US-07, US-08, US-09, US-10, US-11, US-12 | Unit 3 (+ Unit 4 for Watch AC in US-07) |
| Apple Watch Experience | US-13, US-14 | Unit 4 |
| Post-Workout & Session Summary | US-15 | Unit 3 |
| Session Persistence | US-16, US-17 | Unit 3 |
| History | US-18 | Unit 3 |
| Settings | US-19, US-20 | Unit 2 |
| **All 20 stories assigned** | | |
