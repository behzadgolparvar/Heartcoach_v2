# Phase 6 — Code Summary (Milestones, Reminders, Export, Client PDF)

**Status:** complete. Core + iOS app build; full suite green (134 tests). SECURITY-03 grep clean (incl. notification payloads). Device verification → Build & Test.

## Pure core (`HeartRateCoachCore`)
- `Models/Milestone.swift` — `Milestone`, `MilestoneState`, `WeightGateState`
- `Engine/MilestoneScheduler.swift` — 14-day cadence, overdue days, weight gate (BR-6-1/3)
- `Models/ScheduledReminder.swift` + `Engine/ReminderPlanner.swift` — 4 reminder kinds, no health values in text (BR-6-4/7)
- `Engine/SessionCSV.swift` — per-second CSV incl. phrase_type/phrase_time, gap-tolerant (BR-6-9/11)
- `Models/SessionPlanRow.swift` + `Engine/SessionPlanBuilder.swift` — 60-row projection from the P3 ratio schedule + completion note (BR-6-12/13)
- `ProgressionEngine.plannedType(...)` — schedule projection helper
- `UserProfileV2.milestones` (tolerant Codable)

## Tests (app target; PBT partial)
- `EngagementTests` (8) — milestone due 13/14, gate ok/remind/block, reminder set + no-health-text, CSV header/rows + cue, 60-row plan matching schedule, completion-note frequency, MilestoneState Codable

## App services (behind protocols; mockable)
- `NotificationService : NotificationScheduling` (`UserNotifications`) — auth, schedule/replace by kind, local-only, no health in payloads
- `ExportService : ExportUploading` (FirebaseStorage) — CSV → `users/{uid}/exports/<id>.csv`, best-effort
- `SessionPlanPDFRenderer : SessionPlanRendering` (PDFKit) — §K layout → temp PDF URL

## Wiring
- `AppContainer` — owns the 3 services; injects export into summary VM, notifications into home VM
- `WorkoutSummaryViewModel` — best-effort CSV export after session save
- `HomeViewModel` — milestone due + weight gate on load; schedules reminders; `logMilestone` (weight manual + auto RHR)
- `HomeView` — biweekly check-in card (weight entry); Start blocked when weight overdue ≥2 days; "View my plan (PDF)" → share sheet; notification auth on appear
- `project.yml` — added `FirebaseStorage` to the iOS target

## Security / compliance
- SECURITY-03: no health values in logs or notification payloads (grep clean).
- SECURITY-02: own-data Firebase **Storage rules** specified (infrastructure-design) — owner-deployed.
- SECURITY-01 / consent inherited. 04 N/A.
- PBT (partial): scheduler, gate, planner, CSV, plan-builder covered.

## Deferred / flagged (Build & Test)
- Device verification: notification permission + delivery, Storage upload, PDF share sheet.
- **Owner deploy:** publish Firebase Storage security rules; confirm bucket enabled.
- Q3 "block workout start" behavior → collaborator confirm.
- PDF layout is a simple paginated list (functional); richer styling optional later.
