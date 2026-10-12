# Phase 6 — Code Generation Plan (single source of truth)

**Unit:** Milestones, Reminders, Export, Client PDF · **Type:** brownfield · **Branch:** new_design_Sep_2026
**Design source:** `construction/phase6-engagement/{functional-design,nfr-requirements,nfr-design,infrastructure-design}/*`
**Answers:** Q1–Q9 all A. **Rule:** keep the app building; I/O behind protocols (mockable); best-effort/off-critical-path; SECURITY-03 (no health in logs or notification payloads).

## Milestone
Biweekly milestone prompt (weight + auto RHR) with Day-2 workout-start gating; local notifications for session/milestone/weight/nudge (permission at reminders step); per-session CSV uploaded to Firebase Storage on save; per-stage client PDF generated at stage entry via share sheet. All three stages' schedules feed the PDF.

## Naming / reuse
New core: `Milestone`/`MilestoneState`, `MilestoneScheduler`, `WeightGate`, `ReminderKind`/`ScheduledReminder`/`ReminderPlanner`, `SessionCSV`, `SessionPlanRow`/`SessionPlanBuilder`. New app services: `NotificationService`, `ExportService`, `SessionPlanPDFRenderer` (behind protocols). Reuse `Schedule`, `ProgressionEngine`, `Session`/`hr_stream`, HealthKit RHR, Firestore service.

---

## Step 1 — Milestone + reminder + CSV + plan core (`HeartRateCoachCore`, pure)  [x]
- [x] `Models/Milestone.swift` (+ `MilestoneState`), `Engine/MilestoneScheduler.swift`, `Engine/WeightGate.swift` (BR-6-1/2/3)
- [x] `Models/ScheduledReminder.swift` (`ReminderKind`) + `Engine/ReminderPlanner.swift` (BR-6-4/5/7)
- [x] `Engine/SessionCSV.swift` (BR-6-9/11)
- [x] `Models/SessionPlanRow.swift` + `Engine/SessionPlanBuilder.swift` (60-row projection from P3 schedule; projected-completion note) (BR-6-12/13)
- [x] Add `MilestoneState` to `UserProfileV2` (tolerant Codable)

## Step 2 — Core tests (app test target; PBT partial)  [x]
- [x] `MilestoneSchedulerTests` / `WeightGateTests` — 13/14/15-day due; 0/1/2 overdue → ok/remind/block
- [x] `ReminderPlannerTests` — correct set per inputs; no health values in text; re-plan stable
- [x] `SessionCSVTests` — row-per-second incl. gaps + phrase fields
- [x] `SessionPlanBuilderTests` — 60 rows; Type matches ratio schedule; completion note
- [x] `UserProfileV2` round-trip incl. `MilestoneState`

## Step 3 — Service protocols + impls (app)  [x]
- [x] `NotificationScheduling` + `NotificationService` (`UserNotifications`): request auth; schedule/cancel by `ReminderKind` id; replan
- [x] `ExportUploading` + `ExportService` (Firebase Storage): upload CSV to `users/{uid}/exports/<id>.csv`, best-effort/offline-deferred
- [x] `SessionPlanRendering` + `SessionPlanPDFRenderer` (PDFKit): render §K layout → temp URL + saved copy
- [x] `MockNotification`/`MockExport`/`MockPDF` for tests

## Step 4 — Wiring (app)  [x]
- [x] Milestone prompt (weight entry + auto RHR read) surfaced on due; append to history; persist; replan reminders
- [x] Weight gate on the Start-workout path (Day ≥2 → block until logged) alongside existing gates
- [x] Export: call `ExportService` after session save (WorkoutSummaryViewModel/FirestoreService path)
- [x] Notifications: request auth at reminders step; schedule on load + replan on schedule/preference edits
- [x] PDF: generate + share at stage entry (onboarding complete / Level Up / Shape unlock); "View my plan" button on Home
- [x] `project.yml`: add `FirebaseStorage`; `xcodegen generate`

## Step 5 — Build, test, verify  [x]
- [x] build iOS + core; full test suite
- [x] **SECURITY-03 grep:** no milestone/RHR/weight/HR/score values in any logging call site **or notification payload**
- [x] Code summary in `construction/phase6-engagement/code/`
- [x] (Build & Test) device: notification permission + delivery; Storage upload; PDF share — flagged

---

### Scope estimate
~5 steps, ~20–24 files (core logic + 3 app services + wiring). Pure core (Steps 1–2) lands first and is fully testable; services (Step 3) are protocol-isolated; wiring (Step 4) is additive. The only infra touch is adding `FirebaseStorage` + the Storage rules (owner-deployed).

### Traceability
FR-7 (reminders), FR-8 (export), FR-10 (milestones), FR-11 (client PDF), §373 #1/#3/#5 · BR-6-1…16 · Phase 6 of the v5 plan. Security: SECURITY-02 Storage rules, SECURITY-03 grep gate (+ payloads). PBT: scheduler, gate, planner, CSV, plan-builder.
