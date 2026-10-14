# Phase 6 — Business Logic Model (Milestones, Reminders, Export, Client PDF)

How the entities + rules compose. Pure core (scheduling/CSV/PDF-plan); app wires notifications, Storage, PDFKit.

## Pure core components
- `MilestoneScheduler` — due + overdue math (BR-6-1/3).
- `WeightGate` — overdue days → `.ok/.remind/.blockWorkout` (BR-6-3).
- `ReminderPlanner` — `plan(schedule, program, milestoneState, now) -> [ScheduledReminder]` (BR-6-4), with no health values in text (BR-6-7).
- `SessionCSV` — `rows(for:) -> String` (BR-6-9/11).
- `SessionPlanBuilder` — `plan(stage, profile) -> [SessionPlanRow]` + projected-completion note (BR-6-12/13).

## App-layer wiring (I/O)
- **Notifications:** a `NotificationService` registers/cancels `UNNotificationRequest`s from `ReminderPlanner` output; re-plans on edits (BR-6-5); requests auth at the reminders step (BR-6-6).
- **Export:** on `Session` save, `ExportService` builds CSV and uploads to Storage `users/{uid}/exports/<id>.csv`, best-effort (BR-6-10).
- **PDF:** a `SessionPlanPDFRenderer` (PDFKit) renders `SessionPlanBuilder` output; invoked at stage entry; share sheet + saved copy (BR-6-14).

## Flows

```
Milestone due (next app open ≥ due, BR-6-1):
   morning prompt → user logs weight; RHR auto-read (nil-tolerant)        // BR-6-2
   → append Milestone; lastMilestoneDate = now; re-plan reminders         // BR-6-5
Weight overdue:
   Day 1 → reminder (push + in-app)                                       // BR-6-3
   Day ≥2 → Start-workout path shows a blocking "log weight" prompt       // BR-6-3

Session save (from summary, P2/P3):
   ExportService.upload(SessionCSV.rows(session))  // best-effort          // BR-6-10

Stage entry (onboarding complete / Level Up unlock / Shape unlock):
   rows = SessionPlanBuilder.plan(stage, profile)                         // BR-6-13
   pdf  = SessionPlanPDFRenderer.render(rows, note, missRules)            // BR-6-14
   → share sheet + save

Reminders (background): session/milestone/weight/nudge fire locally       // BR-6-4
```

## Integration points
- Session reminder body uses `ProgressionEngine.assign` (today's type) + protocol duration.
- Relapse nudge reuses P3 `lastCountedSessionDate` (the in-app path shipped in P3; P6 adds the push).
- Weight-gate hooks the **Start-workout path** (alongside HealthKit-auth / Shape-choice gating).
- PDF table reuses the P3 ratio schedule projected across 60 sessions.

## Data additions (persisted under `v2profile`)
- `MilestoneState` (lastMilestoneDate, history).

## New dependencies / surface (→ Infrastructure Design)
- `UserNotifications` (local) + permission; Firebase **Storage** + own-data Storage rules; **PDFKit** (built-in). `Info.plist`: notifications usage; HealthKit background already present.

## Testing focus (PBT partial)
- `MilestoneScheduler.isDue` / overdue-days boundaries (13/14/15 days; 0/1/2 overdue).
- `WeightGate` state transitions.
- `ReminderPlanner`: correct set per inputs; no health values in text; stable across re-plan.
- `SessionCSV`: row-per-second mapping incl. gaps + phrase fields round-trip.
- `SessionPlanBuilder`: 60 rows; Type matches the ratio schedule; projected-completion math.

## Out of scope
Maintain; Twilio; privacy policy (healthy-only).
