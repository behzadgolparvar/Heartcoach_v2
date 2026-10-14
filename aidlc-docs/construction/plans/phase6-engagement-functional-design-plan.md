# Phase 6 — Milestones, Reminders, Export & Client PDF · Functional Design Plan

**Scope (v5 re-plan):** the non-training systems that wrap the program.
- **Milestones (§H / FR-10):** biweekly morning RHR (app-monitored) + weight (self-reported); weight-entry gating (Day 1 miss → reminder; Day 2 miss → blocked until logged)
- **Reminders (FR-7):** local push from the schedule (today's session + duration); auto-adjust on preference edits; + the deferred relapse/minimum nudge (P3) and milestone/weight reminders
- **Export (FR-8):** per-session CSV/XLSX to Firebase Storage incl. `phrase_type`/`phrase_time`, hidden from the user (research)
- **Client PDF (§K / FR-11):** per-stage session-plan PDF (projected completion, column key, miss rules, full session-by-session table), delivered post-onboarding + at each stage transition

**Spec source:** `hr-coaching-app-full-spec.md` §H, §I, §K, FR-7/FR-8, developer-owned decisions (§373 #1,#3,#5). **Inputs:** P1b schedule + `lastCountedSessionDate` (P3); P2 `hr_stream` (phrase-tagged); P3 ratio schedule (for the PDF table).
**New surface:** `UserNotifications` (local), Firebase **Storage** (export), **PDFKit** (PDF) → Infrastructure Design will run (not skipped).
**Not in Phase 6:** Maintain; Twilio calls (push equivalent only, §373 #1).

## Design steps (tracked)
- [x] Milestone model + biweekly scheduling + weight-gating
- [x] Local notification scheduling (session + milestone + nudge)
- [x] Session export (CSV flatten + Storage upload)
- [x] Client session-plan PDF generation (per stage)
- [x] Domain entities + business rules

---

## Question 1 — Milestone cadence & trigger
"Biweekly, in the morning."

A) **Due every 14 days; store `lastMilestoneDate`; surface a morning prompt on the next app open on/after the due date** (plus an optional local notification) (recommended)
B) Fixed calendar day-of-week every 2 weeks
X) Other (describe after [Answer]:)

[Answer]: A

## Question 2 — RHR + weight capture
RHR "app-monitored"; weight "self-reported."

A) **RHR auto-read from HealthKit resting HR at milestone time; weight via a manual entry field**; store both in a milestone record (recommended)
B) Both manual
X) Other (describe after [Answer]:)

[Answer]: A

## Question 3 — Weight-entry gating ("Day 2 missed → blocked until logged")
What does "blocked" block?

A) **Block starting a new workout** until the due weight is logged (Day 1 = reminder only; Day 2 = a blocking prompt on the Start path that must be satisfied first) — safety-neutral, nudges logging without losing data (recommended)
B) Block the whole app (hard gate on launch)
C) Never truly block — escalate reminders only
X) Other (describe after [Answer]:)

[Answer]: A

## Question 4 — Which local notifications we schedule (FR-7 + deferred)
A) **Session reminders** (schedule-driven: today's session + duration), **milestone-due**, **weight Day-1 reminder**, and the **relapse/minimum nudge** (deferred from P3) — all local `UserNotifications`; reschedule on preference/schedule edits (recommended)
B) Session reminders only (defer milestone/nudge notifications)
X) Other (describe after [Answer]:)

[Answer]: A

## Question 5 — Notification permission request timing
A) **Request at first schedule/reminders-consent point** (reminders consent already captured at onboarding); if denied, the app works fully, just no pushes (recommended)
B) Request at app launch
X) Other (describe after [Answer]:)

[Answer]: A

## Question 6 — Export format & contents (FR-8)
"Per-session CSV/XLSX … incl. `phrase_type`/`phrase_time` … hidden from user."

A) **CSV per session** (one row per `hr_stream` second: time, hr, zone, phase, target, phrase_type, phrase_time) + a session-summary header; upload to Firebase **Storage** under `users/{uid}/exports/`; invisible in the UI (recommended)
B) XLSX instead of CSV
C) Both CSV + XLSX
X) Other (describe after [Answer]:)

[Answer]: A

## Question 7 — Export trigger
A) **On session save** (after the Firestore write), upload the CSV best-effort; failure is non-blocking and retried on next save (recommended)
B) Batch/manual export
X) Other (describe after [Answer]:)

[Answer]: A

## Question 8 — Client PDF generation approach (§373 #5, developer-owned)
A) **PDFKit (built-in), generated on-device** — no dependency; renders the §K layout (projected completion, column key, miss rules, full 60-session table from the deterministic ratio schedule) (recommended)
B) An HTML→PDF or third-party library
X) Other (describe after [Answer]:)

[Answer]: A

## Question 9 — Client PDF: when generated & where it goes
"Delivered post-onboarding and at the start of each subsequent phase."

A) **Generate on entering a stage** (post-onboarding = Foundation; and at each unlock), offer via the share sheet + save a copy; the 60-session table is computed from the stage's ratio schedule (P3) for the user's classification (recommended)
B) Generate on demand from a button only
X) Other (describe after [Answer]:)

[Answer]: A

---

### After answers
I'll generate the functional-design artifacts under `aidlc-docs/construction/phase6-engagement/functional-design/`, then present the 2-option completion gate. (NFR Requirements + Infrastructure Design will have real content this phase — notifications permission, Storage rules, PDF.)
