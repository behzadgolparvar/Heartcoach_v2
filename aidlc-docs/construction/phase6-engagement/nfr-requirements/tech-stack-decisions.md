# Phase 6 — Tech Stack Decisions (Milestones, Reminders, Export, Client PDF)

Mostly reuse, with **three new (built-in / existing-SDK) technologies** — no new third-party packages.

| Concern | Decision | Status |
|---|---|---|
| Scheduling / CSV / PDF-plan logic | `HeartRateCoachCore` (pure) | Reused package, new types |
| Local notifications | **`UserNotifications`** (Apple, built-in) | **New (OS framework)** |
| Research export storage | **Firebase Storage** (already in the Firebase SDK) | **New (existing SDK module)** |
| PDF generation | **PDFKit** (Apple, built-in) — Q8 | **New (OS framework)** |
| RHR capture | HealthKit resting HR | Reused (P1) |
| Ratio schedule (PDF table) | P3 `ProgressionEngine` | Reused |
| Persistence | Firestore `v2profile` (+ `MilestoneState`) | Reused |
| Testing / project gen | app test target + PBT; xcodegen | Reused |

**No new third-party dependencies** — all three new capabilities are Apple frameworks or an already-linked Firebase module.

## Placement
- `Milestone`/`MilestoneState`, `MilestoneScheduler`, `WeightGate`, `ReminderKind`/`ScheduledReminder`/`ReminderPlanner`, `SessionCSV`, `SessionPlanRow`/`SessionPlanBuilder` → `HeartRateCoachCore`.
- `NotificationService` (UserNotifications), `ExportService` (Storage), `SessionPlanPDFRenderer` (PDFKit) → app (behind protocols for testability).
- Milestone prompt + weight gate (Start path) + PDF share → app `Views/`.

## Infrastructure Design — RUNS (not skipped)
New infra to specify: notification permission + categories, Firebase **Storage** bucket + **own-data security rules**, `Info.plist` notification usage, PDF output location. See infrastructure-design/.
