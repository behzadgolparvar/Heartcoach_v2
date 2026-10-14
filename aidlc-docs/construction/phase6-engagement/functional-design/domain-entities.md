# Phase 6 — Domain Entities (Milestones, Reminders, Export, Client PDF)

Technology-agnostic. Pure logic (scheduling math, CSV flatten, PDF model) in `HeartRateCoachCore`; app wires `UserNotifications`, Firebase Storage, PDFKit. Decisions: Q1–Q9 all A.

## 1. Milestones (§H / FR-10)

### `Milestone`
A biweekly outcome record.
- `date: Date`, `restingHR: Int?` (HealthKit; nil-tolerant, Q2), `weightKg: Double?`

### `MilestoneState` (on profile, persisted)
- `lastMilestoneDate: Date?` — seeds the 14-day cadence (Q1)
- `history: [Milestone]` — trend (research + display)
- Derived: `isDue(asOf:)` = `now ≥ lastMilestoneDate + 14d` (or never logged)
- Derived: `weightOverdueDays(asOf:)` → 0 / 1 / ≥2 (drives gating, Q3)

### `MilestoneScheduler` (pure)
- `isDue(last:now:) -> Bool`, `daysOverdue(due:now:) -> Int`.

## 2. Weight-entry gating (§H, Q3)
- `WeightGate.state(overdueDays:) -> { .ok | .remind | .blockWorkout }` (Day 1 → remind; Day 2+ → block workout start). Weight-only (RHR auto).

## 3. Reminders (FR-7, Q4/Q5)

### `ReminderKind`
`sessionDue | milestoneDue | weightReminder | relapseNudge`.

### `ScheduledReminder` (value)
- `kind`, `fireDate: DateComponents`/`Date`, `title`, `body` (no health values — SECURITY-03)

### `ReminderPlanner` (pure)
- `plan(schedule:program:milestoneState:now:) -> [ScheduledReminder]` — session reminders from `Schedule` (preferred days/time, body = "Today: <type> · ~<min> min"); milestone-due morning; weight Day-1; relapse nudge when a gap is detected (reuses P3 `lastCountedSessionDate`). App layer registers/cancels via `UserNotifications`; replan on schedule/preference edits.

## 4. Export (FR-8, Q6/Q7)

### `SessionCSV` (pure)
- `rows(for session:) -> String` — header (session summary: id, date, type, score, durations) + one line per `hr_stream` second: `timeSec, hr, currentZone, phase, targetZone, phrase_type, phrase_time`.
- Data-gap tolerant (missing seconds simply absent, §373 #4).

### Upload (app)
- On session save (after Firestore write), best-effort upload CSV to Firebase **Storage** at `users/{uid}/exports/<sessionId>.csv`; failure non-blocking, retried next save. Hidden from UI.

## 5. Client session-plan PDF (§K / FR-11, Q8/Q9)

### `SessionPlanRow` (pure)
- `sessionNumber`, `type: WorkoutType`, `focus: String`, `intensity: String`, `durationMin: Int`.

### `SessionPlanBuilder` (pure)
- `plan(stage:profile:) -> [SessionPlanRow]` — enumerates all 60 sessions by walking the P3 ratio schedule for the user's classification (per `ProgressionEngine` assignment logic, extended to project forward), filling Type + Focus/What-to-Expect (rotating pairs) + Intensity + Duration.
- `projectedCompletionNote(frequencyPerWeek:) -> String` (§B frequency→months, framed toward next stage).

### PDF render (app)
- `PDFKit` renders: title, projected-completion note, column key, miss-session rules (incl. non-negotiable minimum), the 60-row table. Generated on stage entry (post-onboarding + each unlock); delivered via share sheet + saved copy.

## 6. Reuse / new surface
Reuse: P1b `Schedule`, P2 `hr_stream`/`Session` (phrase-tagged + score fields), P3 `ProgressionEngine` schedule, HealthKit RHR (P1). New: `UserNotifications` (local), Firebase **Storage**, **PDFKit** → Infrastructure Design. Out: Maintain; Twilio (push equivalent only).
