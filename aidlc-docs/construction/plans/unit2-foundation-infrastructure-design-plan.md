# Infrastructure Design Plan — Unit 2: iPhone Foundation

## Execution Checklist

- [x] Step 1: Analyze design artifacts
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers — no ambiguities
- [x] Step 6: Generate infrastructure design artifacts
- [ ] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit2-iphone-foundation/infrastructure-design/infrastructure-design.md`
- [x] `aidlc-docs/construction/unit2-iphone-foundation/infrastructure-design/deployment-architecture.md`

---

## Infrastructure Category Assessment

| Category | Applicable | Reason |
|---|---|---|
| Deployment Environment | Yes | Firebase project setup (Google Cloud) |
| Compute Infrastructure | N/A | App runs on-device; no server-side compute |
| Storage Infrastructure | Yes | Firestore (cloud) + Core Data (on-device) — already decided |
| Messaging Infrastructure | N/A | No queues or event buses needed |
| Networking Infrastructure | N/A | Firebase SDK handles all networking |
| Monitoring Infrastructure | Yes | Crash reporting decision needed |
| Shared Infrastructure | Yes | Firebase project shared across all units |

---

## Infrastructure Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
Should separate Firebase projects be used for development and production?

A) **Single Firebase project** — one project used for everything (development + production). Simpler setup; `GoogleService-Info.plist` is the same everywhere. Suitable for a solo developer building v1.
B) **Two Firebase projects** — `heartcoach-dev` and `heartcoach-prod`. Development testing doesn't touch production data. Requires maintaining two `GoogleService-Info.plist` files and switching between them per build configuration (Debug vs Release).
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
Should Firebase Crashlytics be added for crash reporting?

A) **Yes — add Crashlytics** — automatic crash reports with stack traces sent to Firebase console. Helps identify and fix crashes in production. Adds `FirebaseCrashlytics` as an SPM dependency.
B) **No — skip Crashlytics for v1** — rely on Xcode Organizer and TestFlight crash logs for now. Can add Crashlytics later without major changes.
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

Please fill in all answers and let me know when you're done.
