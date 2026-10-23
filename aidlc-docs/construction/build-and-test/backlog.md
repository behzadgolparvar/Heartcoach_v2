# HeartCoach v5 — Build & Test Backlog

Branch `new_design_Sep_2026`. All 6 feature phases complete; 134 unit tests green. This tracks the device-dependent + deferred work to close before a wider TestFlight release. Check items off as done.

## A. Deferred §J safety (from Phase 2 — wire into the v2 session driver)
- [x] **Sensor dropout:** 20s no reading → yellow banner "safety checks paused"; HR recording gaps are implicit; clears on return (SafetyPolicy.sensorDropoutSec) — wired, device-verify
- [x] **Pause/resume:** 15-min resume prompt (Continue / Finish / Need More Time), max 3×10-min snoozes; safety off while paused (tick loop cancelled) — wired, device-verify
- [~] **Elevated starting HR → `walk_fallback`:** on first HR reading, if >40% HRR above resting → switch to a 30-min brisk/easy walk session, flagged `walk_fallback`, excluded from progression. NOTE: implemented as a start-time decision; the spec's "5-min settle walk then re-check" is a device-tuning refinement (TODO).
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
- [~] Research export: now **Firestore-only** (hr_stream has epoch-ms timestamps); Storage CSV upload **disabled/commented** in WorkoutSummaryViewModel (code kept). TODO: on-demand **Firestore→CSV export script** (Node or Python) when research data is needed.
- [ ] Client PDF generates + share sheet works per stage
- [ ] Milestone check-in: auto RHR read + weight gate (Day-2 blocks Start)

## D. Owner deploy steps (console)
- [x] Publish Firebase **Storage** own-data security rules (`users/{uid}/exports/**`) — DONE (Blaze linked, bucket `heartcoach-dcec5.firebasestorage.app`, rules published 2026-10-12)
- [x] Confirm a Storage bucket is enabled on the project — DONE (regional US-EAST1, no-cost)
- [x] **`GoogleService-Info.plist` bucket check** — verified: existing plist's `STORAGE_BUCKET` already = `heartcoach-dcec5.firebasestorage.app` (matches the created bucket). No re-download needed.
- [ ] (Firestore rules already published in an earlier cycle)
- [ ] **Auth email deliverability (spam) — before wider release (2026-10-22):** reset emails land in spam because the default sender `noreply@heartcoach-dcec5.firebaseapp.com` is a shared Firebase domain with no SPF/DKIM/DMARC for our brand. Fix: route auth emails via custom SMTP (SendGrid/Mailgun/SES/Postmark — free tiers) in Authentication → Templates → SMTP settings, from an owned domain with SPF+DKIM+DMARC set up. Needs a domain + DNS. Solves branding too (same owned-domain work). NOTE: SMTP settings may be blocked by the same "template updates unavailable" restriction — check / contact Firebase support. Interim: app confirmation now says "check inbox and spam folder".
- [ ] **Auth email branding (cosmetic, deferred 2026-10-22):** password-reset email shows the project ID "heartcoach-dcec5" instead of "HeartCoach" because the template's `%APP_NAME%` resolves to the public-facing name (= project ID). Feature itself works (email + link verified). Blocked path: Firebase Console → Authentication → Templates edit is currently disabled for this project ("Email template updates are currently unavailable"). Fix options when revisited: (a) wait/contact Firebase support to unblock template edits, then set Sender name + replace `%APP_NAME%`; or (b) set the public-facing name via Google Cloud (heartcoach-dcec5 project → OAuth consent "App name") so `%APP_NAME%` → HeartCoach across all auth emails. Sender domain `@heartcoach-dcec5.firebaseapp.com` + link domain need a custom domain (bigger task, likely skip).

## E. Collaborator confirmations (safety-relevant, flagged in FDs)
- [ ] Leg-exercise bank: built on §G's 8; spec line 59 says "20+" — expand? + confirm per-exercise **mode (bilateral/unilateral)** and **impacted-joint** tags (P4)
- [ ] Weight-exercise banks (§G, 6/muscle) transcription + exercise↔muscle mapping + load guidance (P5)
- [ ] Q3 "blocked until logged" = **block starting a workout** (P6) — confirm acceptable
- [ ] Shape HIIT 10-sec overage (35:10) — spec says accepted as-is (§387 #3), no action

## F. Release notes
- Q8=B: pre-v5 testers **re-onboard once** (old profiles aren't v5-complete). Keep builds internal until §A is wired. TestFlight: bump build number before upload.

## Status (2026-10-12)
- Feature code: **complete** (P1–P6). §J safety **wired** (A: dropout + pause prompt done; walk_fallback done, 5-min-recheck refinement = TODO). Unit/PBT: **139 green**. Security (SECURITY-01/02/03): satisfied; **Storage own-data rules published (D done)**.
- **Remaining = device/collaborator only:** B (coaching device-tuning), C (on-device verification), E (collaborator confirms). No further pure-code work outstanding.
- Next action is a **physical-device build + integration pass**; then internal TestFlight (testers re-onboard once, Q8=B).


## G. Optional future enhancements (not in v5 spec)
- [ ] **Remote Config** for collaborator-tunable constants (score tiers, Shape-HIIT offsets, bank size, reminder copy) — change values from console without an app update; free tier.
- [ ] **Gemini / Firebase AI Logic** — any in-app AI feature is pay-per-token AND would conflict with the deterministic/testable coaching + health-data privacy (SECURITY-03). Out of scope; a deliberate product/privacy/cost decision if ever pursued. (Console "Gemini in Firebase" dev-assistant is free and fine.)
