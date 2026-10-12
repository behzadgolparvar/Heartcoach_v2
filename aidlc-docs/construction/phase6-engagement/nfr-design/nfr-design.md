# Phase 6 — NFR Design (Milestones, Reminders, Export, Client PDF)

How the NFR requirements are realized. Concise; patterns + placements.

## 1. Purity / separation of I/O
- All decision logic is pure (`MilestoneScheduler`, `WeightGate`, `ReminderPlanner`, `SessionCSV`, `SessionPlanBuilder`) with injected `now`/inputs → deterministic, testable.
- The three I/O capabilities sit behind **protocols** in the app so they're mockable and swappable:
  - `NotificationScheduling` (impl: `UserNotifications`)
  - `ExportUploading` (impl: Firebase Storage)
  - `SessionPlanRendering` (impl: PDFKit)

## 2. Off-critical-path patterns
- **Export:** triggered after the Firestore session write succeeds; runs in a detached task; failure logged as a non-health diagnostic and retried on next save. Never delays save or summary UI.
- **PDF:** generated in a background task at stage entry with a progress indicator; the share sheet appears on completion.
- **Notifications:** scheduled/cancelled asynchronously; never gate a user action.

## 3. Reliability patterns
- **Best-effort + graceful denial:** notification auth denial → skip scheduling, keep in-app prompts. Export failure → enqueue a lightweight retry marker; next successful save flushes.
- **Offline:** milestones/gating/PDF use local state + Firestore cache; Storage upload waits for connectivity (Firebase handles resumable upload).
- **Data gaps:** CSV emits only present seconds; PDF/plan never assume contiguous data (§373 #4).

## 4. Security patterns
- **No health in logs or notifications (SECURITY-03):** Code-Gen grep-check over the new types + notification payload builders → zero HR/score/weight/RHR values. Notification bodies are built from session *type* + duration only.
- **Own-data Storage (SECURITY-02):** Firebase Storage rules allow read/write to `users/{uid}/exports/**` only for `request.auth.uid == uid` — mirrors the Firestore rules (specified in Infrastructure Design).
- **Encryption (SECURITY-01):** Storage TLS + at-rest; no new secrets (04 N/A).

## 5. Testability
- `now` injected into milestone/reminder logic → exact boundary tests (13/14/15 days; 0/1/2 overdue).
- I/O protocols mocked → assert "export attempted with correct path", "N notifications scheduled", "plan has 60 rows matching the ratio schedule", without touching the OS/network.

## 6. Usability
- Weight gate blocks only the Start path with a clear "log weight to continue"; everything else usable.
- PDF via standard share sheet (send/print/Files) + saved copy.
- Notification copy concise; lock-screen-safe.

## 7. Component / placement map
| Concern | Component | Location |
|---|---|---|
| Milestone/gate/reminder/CSV/plan logic | pure types | `HeartRateCoachCore` |
| Notifications | `NotificationService : NotificationScheduling` | app `Services/` |
| Export upload | `ExportService : ExportUploading` | app `Services/` |
| PDF render | `SessionPlanPDFRenderer : SessionPlanRendering` | app `Services/` |
| Milestone prompt + weight gate + PDF share | views | app `Views/` |

## 8. Infrastructure Design — RUNS
Notification permission/categories + `Info.plist`; Firebase **Storage** bucket + own-data security rules; PDF output location. Specified in `infrastructure-design/`.
