# Unit of Work Plan — HeartRateCoach

## Execution Checklist

### Part 1 — Planning
- [x] Step 1: Create decomposition plan (this document)
- [x] Step 2: Include mandatory artifacts in plan
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Request user input → answers received
- [x] Step 6: Collect answers
- [x] Step 7: Analyze answers — no ambiguities found
- [x] Step 8: Follow-up questions — not needed
- [ ] Step 9: Request approval

### Part 2 — Generation
- [x] Step 12: Load plan
- [x] Step 13: Generate unit-of-work.md — DONE
- [x] Step 14: Generate unit-of-work-dependency.md — DONE
- [x] Step 15: Generate unit-of-work-story-map.md — DONE
- [ ] Step 16: Present completion message
- [ ] Step 17: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/inception/application-design/unit-of-work.md`
- [x] `aidlc-docs/inception/application-design/unit-of-work-dependency.md`
- [x] `aidlc-docs/inception/application-design/unit-of-work-story-map.md`

---

## Proposed Unit Structure (from Execution Plan + Application Design)

The 4-unit structure is already well-defined. These 3 questions resolve the remaining boundary decisions.

| Unit | Name | Core Contents |
|---|---|---|
| 1 | HeartRateCoachCore (SPM) | Models, ZoneCalculator, WorkoutProgram, WorkoutPhaseSequencer |
| 2 | iPhone Foundation | Auth, Onboarding, Settings, Firebase profile/zones, HealthKit auth |
| 3 | iPhone Workout Engine | CoachingEngine, WatchBridge, WorkoutSessionManager, live workout UI, session persistence |
| 4 | Apple Watch App | WatchSessionManager, WatchConnectivityManager, HapticManager, Watch views |

---

## Decomposition Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
Where should the **Home screen** (workout selection + last session summary) live?

A) Unit 2 — iPhone Foundation (Home is a simple display screen; after Unit 2, the app can be launched and navigated even without the coaching engine)
B) Unit 3 — iPhone Workout Engine (Home is the entry point to starting a workout — logical to build it alongside the workout flow it launches)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
Where should the **History screen** (list of past sessions) and **Session Summary screen** (post-workout stats) live?

A) Unit 2 — iPhone Foundation (both screens only read from Firebase; no coaching engine dependency; completing them in Unit 2 means a working read-only data layer is verified early)
B) Unit 3 — iPhone Workout Engine (both screens appear after a workout ends; natural to build them alongside the workout flow that produces the data)
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

### Question 3
How should the Xcode project file be managed?

A) Hand-crafted Xcode project (`.xcodeproj`) — standard approach, managed directly in Xcode GUI
B) Tuist or XcodeGen — project file generated from a manifest (`Project.swift` or `project.yml`); never commit the `.xcodeproj` (cleaner git history, resolves merge conflicts on project file)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in all answers and let me know when you're done.
