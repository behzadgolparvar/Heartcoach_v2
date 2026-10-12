# Phase 6 — NFR Requirements (Milestones, Reminders, Export, Client PDF)

**Note:** unlike P2–P5, Phase 6 adds new surface — `UserNotifications` (local), Firebase **Storage**, **PDFKit**. The core logic (scheduling, CSV, PDF-plan) is pure; the I/O is app-layer. Key choices were settled in Functional Design, so **no new NFR questions** — this records the requirements the new surface imposes. Infrastructure Design runs (not skipped).

## Performance
- `MilestoneScheduler`/`WeightGate`/`ReminderPlanner`/`SessionCSV`/`SessionPlanBuilder` are O(n) over small inputs (60 sessions / ~2000 CSV rows) → sub-10ms, off the hot path.
- PDF render (60-row table) is a one-off at stage entry — background-friendly; must not block the UI.
- CSV upload is best-effort and **off the session-save critical path** (failure non-blocking).
- **Requirement:** no added latency to session save or app launch; PDF generation shows progress and never blocks.

## Reliability
- **Notifications best-effort:** denial or scheduling failure never breaks the app; in-app prompts (milestone/weight) still function.
- **Export resilience:** upload failure is queued/retried on next save; never loses or blocks the session (Firestore write already succeeded).
- **Data-gap tolerance (§373 #4):** CSV handles missing seconds as absent rows; PDF/plan math tolerates incomplete data.
- **Offline:** milestones/gating/PDF work offline (local + Firestore cache); Storage upload defers until online.

## Security (Baseline — Full/blocking)
| Rule | P6 | How |
|---|---|---|
| SECURITY-03 no PII/health in logs **or notification payloads** | **Primary** | BR-6-7/15 — payloads carry only session type + duration / generic nudge |
| SECURITY-01 encryption | Yes | Storage CSV over TLS + at-rest (Firebase) |
| SECURITY-02 (now relevant) | **Yes** | own-data **Storage rules** restrict `users/{uid}/exports/**` to that user (BR-6-16) |
| Own-data / consent | Yes | reminders consent captured at onboarding; Firestore/Storage own-data |
| SECURITY-04 secrets | N/A | no new secrets; GoogleService-Info stays gitignored |

## Permissions (OS)
- Notification authorization requested at the reminders step; graceful denial (BR-6-6).
- HealthKit resting-HR read reuses existing authorization (P1).

## Testability (PBT partial)
- Pure scheduler/gate/planner/CSV/plan-builder → exhaustive/property tests (cadence + overdue boundaries, reminder set, CSV mapping incl. gaps, 60-row plan vs ratio schedule). Notification/Storage/PDF I/O behind protocols → mockable.

## Usability / accessibility
- Milestone prompt + weight gate are clear, non-destructive; gate blocks only workout start (Q3).
- PDF shareable/printable; notification text concise.

## Out of scope
Maintain; Twilio; privacy policy (healthy-only pilot).
