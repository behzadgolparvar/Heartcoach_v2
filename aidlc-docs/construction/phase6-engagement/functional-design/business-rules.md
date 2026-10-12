# Phase 6 — Business Rules (Milestones, Reminders, Export, Client PDF)

`BR-6-*` namespace. Pure/deterministic and PBT-targetable unless noted (notification/Storage/PDF I/O is app-layer, best-effort).

## Milestones (§H)
- **BR-6-1 (cadence, Q1):** due when `now ≥ lastMilestoneDate + 14 days`, or if never logged; first due seeded at onboarding. Surfaced on next app open on/after due (plus a morning local notification).
- **BR-6-2 (capture, Q2):** RHR read from HealthKit resting HR (nil-tolerant — record weight now, backfill/leave RHR nil if unavailable); weight manual. Both stored in a `Milestone` appended to history; `lastMilestoneDate = completion date`.
- **BR-6-3 (weight gating, Q3):** from the due date — Day 0–<1: ok; Day 1: reminder only; **Day ≥2 without a logged weight: block starting a new workout** until logged. Weight-only; never blocks the whole app; safety-neutral.

## Reminders (FR-7)
- **BR-6-4 (set, Q4):** schedule local notifications for: session-due (from `Schedule`; body = today's assigned session + duration), milestone-due (morning), weight Day-1, relapse nudge (on gap). 
- **BR-6-5 (reschedule):** on any edit to schedule/preferred time, or on milestone/weight completion, cancel and re-plan affected notifications so none are stale.
- **BR-6-6 (permission, Q5):** request notification authorization at the reminders step (consent already captured at onboarding); denial is non-fatal — app works fully, pushes simply don't fire; in-app prompts still appear.
- **BR-6-7 (no health in payloads):** notification title/body carry only session type + duration or a generic nudge — never HR, scores, weight, or other health values (SECURITY-03; lock-screen visible).
- **BR-6-8 (push-not-call):** the §373-#1 "call reminder" is satisfied by a push carrying the same content; no Twilio/calling API.

## Export (FR-8)
- **BR-6-9 (format, Q6):** CSV per session — summary header + one row per `hr_stream` second (`timeSec, hr, currentZone, phase, targetZone, phrase_type, phrase_time`). Pure string build.
- **BR-6-10 (upload, Q7):** on session save, best-effort upload to Firebase Storage `users/{uid}/exports/<sessionId>.csv`; failure is non-blocking and retried on the next save. Hidden from the UI.
- **BR-6-11 (gap tolerance):** missing seconds (sensor dropout) are simply absent rows — never error (§373 #4).

## Client PDF (§K)
- **BR-6-12 (content):** title, projected-completion note (frequency-based, framed toward next stage), column key, miss-session rules incl. non-negotiable minimum, and the full 60-row session table (Session #, Type, Focus/What-to-Expect, Intensity, Duration).
- **BR-6-13 (table source):** the 60 rows are computed by walking the stage's deterministic ratio schedule (P3) for the user's classification — a projection of the same assignment logic, not stored.
- **BR-6-14 (generation, Q8/Q9):** PDFKit on-device, no dependency; generated on stage entry (post-onboarding = Foundation; each unlock = Level Up / Shape); delivered via share sheet + a saved copy re-openable in-app.

## Security (inherited, blocking)
- **BR-6-15 (SECURITY-03):** milestone/weight/RHR values, exported HR data, and PDF contents are health/PII — never console/analytics-logged. CSV lives in the user's own Storage path (own-data Storage rules, mirroring Firestore). Notification payloads carry no health values (BR-6-7).
- **BR-6-16 (Storage rules):** Firebase Storage rules restrict `users/{uid}/exports/**` to that authenticated user (own-data), consistent with Firestore rules.

## Out of scope
Maintain; Twilio calls; privacy policy (healthy-only pilot, §387 #2).
