# HeartCoach v5 — Build & Test Backlog

Branch `new_design_Sep_2026`. All 6 feature phases complete; 134 unit tests green. This tracks the device-dependent + deferred work to close before a wider TestFlight release. Check items off as done.

## A. Deferred §J safety (from Phase 2 — wire into the v2 session driver)
- [ ] **Sensor dropout:** 20s no reading → on-screen prompt; resume in place; data-gap flag; "safety temporarily unavailable" warning
- [ ] **Pause/resume:** 15-min prompt (Continue / Finish / Need More Time), max 3 snoozes × 10 min; safety off while paused (user informed)
- [ ] **Elevated starting HR → `walk_fallback`:** 5-min walk check → settled? normal : full-session 1-min fast / 1-min slow; flag `walk_fallback`, exclude from progression (reuse P3 non-counting plumbing), retain for research
- [ ] Cancel rule (≥20 scored / <20 discarded) — confirm wired via training-time (partially in place)

## B. P4 / P5 coaching refinements (device-tuning)
- [ ] Literal **per-rep synced voice count** during exercise phases (currently: name + rep target + "switch legs", no per-rep count) — needs a sub-second cue timer
- [ ] HIIT **unilateral per-leg** handling (Level Up / Shape currently pace 20 reps as a total)
- [ ] **Shape-HIIT 2-checks-per-50s** run offsets — verify/tune the 15s/40s placement on device
- [ ] Exercise-phase internal 2:10 timing (talk/exercise/rest/walk) — currently folded into `.exercise`(60s)+`.rest` walk; verify feel

## C. On-device verification (all three stages)
- [ ] Watch HR pipeline (WCSession, auto-start, HealthKit) across Foundation / Level Up / Shape
- [ ] Voice + haptics + background workout session; voice-off on-screen fallback
- [ ] Notifications: permission flow + delivery (session / milestone / weight / relapse nudge)
- [ ] Firebase Storage CSV upload (research export) lands at `users/{uid}/exports/`
- [ ] Client PDF generates + share sheet works per stage
- [ ] Milestone check-in: auto RHR read + weight gate (Day-2 blocks Start)

## D. Owner deploy steps (console)
- [ ] Publish Firebase **Storage** own-data security rules (`users/{uid}/exports/**`) — see `phase6-engagement/infrastructure-design/`
- [ ] Confirm a Storage bucket is enabled on the project
- [ ] (Firestore rules already published in an earlier cycle)

## E. Collaborator confirmations (safety-relevant, flagged in FDs)
- [ ] Leg-exercise bank: built on §G's 8; spec line 59 says "20+" — expand? + confirm per-exercise **mode (bilateral/unilateral)** and **impacted-joint** tags (P4)
- [ ] Weight-exercise banks (§G, 6/muscle) transcription + exercise↔muscle mapping + load guidance (P5)
- [ ] Q3 "blocked until logged" = **block starting a workout** (P6) — confirm acceptable
- [ ] Shape HIIT 10-sec overage (35:10) — spec says accepted as-is (§387 #3), no action

## F. Release notes
- Q8=B: pre-v5 testers **re-onboard once** (old profiles aren't v5-complete). Keep builds internal until §A is wired. TestFlight: bump build number before upload.

## Status
- Feature code: **complete** (P1–P6). Unit/PBT: **134 green**. Security (SECURITY-01/02/03): satisfied in code + rules spec; 02 pending the owner rules deploy (D).
