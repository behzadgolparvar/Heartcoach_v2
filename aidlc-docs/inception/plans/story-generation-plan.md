# Story Generation Plan — HeartRateCoach

## Execution Checklist

### Part 1 — Planning
- [x] Step 1: Validate user stories need (see user-stories-assessment.md — EXECUTE)
- [x] Step 2: Create story plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Include mandatory artifacts in plan (stories.md + personas.md)
- [x] Step 5: Present story options (below)
- [x] Step 6: Store story plan (this file)
- [x] Step 7: Request user input → answers received
- [x] Step 8: Collect answers
- [x] Step 9: Analyze answers for ambiguities — no ambiguities found
- [x] Step 10: Follow-up questions if needed — not needed
- [x] Step 13: Plan approved by user

### Part 2 — Generation
- [x] Step 15: Load this plan
- [x] Step 16: Generate personas.md — DONE
- [x] Step 17: Generate stories.md — DONE (20 stories across 8 epics)
- [x] Step 18: Verify all artifacts complete — personas.md + stories.md generated
- [ ] Step 20: Present completion message
- [ ] Step 21: Wait for explicit approval of generated stories

---

## Story Approach Options

| Approach | Description | Best For |
|---|---|---|
| **User Journey-Based** | Stories follow the user's flow through the app end-to-end | Capturing cross-screen workflows (e.g. "complete a workout") |
| **Feature-Based** | Stories organized by system feature (auth, workout, coaching, history) | Technical team hand-off, sprint planning |
| **Screen-Based** | One or more stories per screen | Detailed UI acceptance criteria |
| **Hybrid** | Epics per feature area, stories per user action within each | Balanced coverage — recommended for this project |

**Recommendation**: Hybrid approach — epics per feature area (Onboarding, Workout Execution, Post-Workout, History, Settings) with stories per meaningful user action within each. This maps naturally to the screen structure while capturing the cross-platform Watch + iPhone journeys.

---

## Planning Questions

Please answer each question by filling in the letter after the `[Answer]:` tag.

---

### Question 1
How many user personas should be defined for this app?

A) One — a single "Active Fitness Enthusiast" persona covers all users (simpler, avoids over-engineering)
B) Two — a "Beginner Runner" persona and an "Experienced Athlete" persona (captures different goal/effort levels)
C) Three — Beginner, Intermediate, and Advanced personas (most thorough, highest overhead)
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
What story breakdown approach should be used?

A) Hybrid (epics per feature area, stories per user action — recommended for this project)
B) User Journey-Based (stories follow the user flow end-to-end across screens)
C) Screen-Based (one or more stories per screen)
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 3
What acceptance criteria format should be used for each story?

A) BDD-style: Given / When / Then (precise, directly testable, recommended for coaching engine stories)
B) Bullet-point checklist (simpler, faster to write, good for UI stories)
C) Mixed — BDD for logic-heavy stories (coaching engine, zone calculation), bullet-points for UI/screen stories
D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

### Question 4
Should the Apple Watch user experience have its own dedicated stories, or should Watch behavior be captured as acceptance criteria within the iPhone stories?

A) Dedicated Watch stories — the Watch is a separate screen surface and deserves its own stories
B) Watch as AC within iPhone stories — e.g., the "Start Workout" story includes Watch behavior as acceptance criteria
C) Both — dedicated Watch stories for Watch-specific screens (Emergency Stop, Coaching Overlay) and iPhone stories carry Watch AC for shared flows
D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

### Question 5
Should the offline session queuing feature (FR-11) have its own dedicated story, or be captured within the "Complete Workout" story as acceptance criteria?

A) Dedicated story — offline handling is complex enough to stand alone
B) Acceptance criteria within "Complete Workout" story — it's part of the same user action
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in all answers and let me know when you're done.
