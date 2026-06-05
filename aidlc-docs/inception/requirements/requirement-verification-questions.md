# Requirements Verification Questions — HeartRateCoach

Your PROJECT_BRIEF.md is excellent and covers most of the requirements in detail. The following questions target the remaining gaps before we finalize requirements and begin design.

Please answer each question by filling in the letter after the `[Answer]:` tag. If no option fits, choose the last option (Other) and describe your preference.

---

## Question 1
Do you have an existing Firebase project set up for this app, or should we provision a new one from scratch?

A) I have an existing Firebase project — I will provide the `GoogleService-Info.plist`
B) New Firebase project — set up from scratch as part of the build
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 2
Do you have an active Apple Developer account (required for HealthKit, WatchConnectivity, and device testing)?

A) Yes — I have an active Apple Developer account and can sign/provision targets
B) No — I need guidance on what to set up before the app can run on a device
C) Other (please describe after [Answer]: tag below)

[Answer]: A 

---

## Question 3
What should the Xcode project structure look like for the shared code between iPhone and Watch targets?

A) Swift Package (local SPM package for `Shared/` — cleanest separation, recommended)
B) Shared Xcode group/folder only — no separate package, files added to both targets
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 4
What is your preferred visual design style for the app?

A) Dark mode primary (black/dark backgrounds — common for workout/sport apps)
B) Light mode primary (clean white/light backgrounds)
C) System adaptive — automatically follows iPhone system appearance (light or dark)
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 5
Should the Apple Watch app support a watch face complication (so users can start a workout directly from the watch face)?

A) Yes — include a basic complication that deep-links into the workout selection
B) No — not in v1, users launch from the watch app icon only
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 6
The PROJECT_BRIEF.md lists voice feedback (AVSpeechSynthesizer) as running on iPhone. Should voice coaching also be audible through Apple Watch's speaker, or iPhone only?

A) iPhone speaker only (earphones plugged into iPhone, or iPhone nearby)
B) Apple Watch speaker only (better for users without earphones — watch is on wrist)
C) Both — play on Watch speaker if iPhone speaker is not active
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 7
After a workout ends, should the session be saved even if the user is offline (no internet connection at the time)?

A) Yes — queue the session locally and sync to Firebase when connection is restored
B) No — if offline, show an error; user must be connected to save
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 8 — Security Extension
Should security extension rules be enforced for this project? This includes rules around HealthKit data handling, Firebase Auth token management, and Keychain storage.

A) Yes — enforce all SECURITY rules as blocking constraints (recommended — this app handles sensitive health data)
B) No — skip all SECURITY rules (suitable for PoCs or prototypes)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 9 — Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project? The Karvonen zone calculator and coaching engine contain pure mathematical functions that are ideal candidates for PBT.

A) Yes — enforce all PBT rules as blocking constraints (recommended — zone math benefits from exhaustive property testing)
B) Partial — enforce PBT only for the zone calculator and coaching engine (pure functions)
C) No — skip PBT rules
D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

Please fill in all answers and let me know when you're done.
