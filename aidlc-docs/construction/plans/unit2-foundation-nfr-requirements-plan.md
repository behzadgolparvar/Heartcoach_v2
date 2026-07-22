# NFR Requirements Plan — Unit 2: iPhone Foundation

## Execution Checklist

- [x] Step 1: Analyze functional design
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers — no ambiguities; Q3 refinement noted (instructions + "Open Settings" link)
- [x] Step 6: Generate NFR artifacts
- [ ] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit2-iphone-foundation/nfr-requirements/nfr-requirements.md`
- [x] `aidlc-docs/construction/unit2-iphone-foundation/nfr-requirements/tech-stack-decisions.md`

---

## Context Summary

Unit 2 has real infrastructure: Firebase Auth, Firestore, HealthKit, Core Data, and network monitoring. Four questions target the genuine decisions that affect security rules, data structure, offline behavior, and privacy.

---

## NFR Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
How should Firestore data be structured per user?

A) **Single user document with nested maps** — one document at `users/{userID}` containing profile, zones, and settings as nested fields. Sessions are a subcollection `users/{userID}/sessions/{sessionID}`.
B) **Separate top-level collections** — `profiles/{userID}`, `zones/{userID}`, `sessions/{userID}/records/{sessionID}` as separate top-level collections.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
Should Firebase Firestore offline persistence be enabled?

A) **Yes — enable Firestore offline cache** — Firestore automatically caches reads locally; profile and zones load instantly on relaunch even without network. Writes queue and sync automatically when connection returns.
B) **No — rely only on the manual OfflineSessionQueue** — simpler; only session data is queued offline (as already designed). Profile and zones require connectivity to load.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 3
What should happen if the user denies HealthKit heart rate access during onboarding?

A) **Warn and continue** — onboarding completes normally; a persistent warning banner appears on the Home screen and a non-dismissible alert appears when the user tries to start a workout. User must go to Settings → Health to fix it.
B) **Block workout start** — onboarding completes; the Start Workout button is disabled (greyed out) with a label explaining why until HealthKit access is granted.
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

### Question 4
How many past sessions should be loaded on the Home screen?

A) **Load only the most recent 1 session** — Home only needs `lastSession` for the summary card; full history is loaded when the user opens the History tab (Unit 3).
B) **Load all sessions** — load the complete session list up front so the History tab has data ready immediately when opened.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in all answers and let me know when you're done.
