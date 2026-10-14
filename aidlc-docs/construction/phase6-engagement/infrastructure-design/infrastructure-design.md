# Phase 6 — Infrastructure Design (Milestones, Reminders, Export, Client PDF)

The only phase with new infrastructure. All of it is Apple frameworks or existing-SDK/Firebase config — **no new third-party packages, no servers**.

## 1. Local notifications (`UserNotifications`)
- **Framework:** `UserNotifications` (built-in). No APNs/server — all notifications are **locally scheduled** on-device.
- **Permission:** request `UNUserNotificationCenter.requestAuthorization([.alert, .sound])` at the reminders step (reminders consent captured at onboarding). Denial is non-fatal.
- **Categories/identifiers:** stable identifiers per `ReminderKind` (`session`, `milestone`, `weight`, `nudge`) so re-planning can cancel/replace precisely (`removePendingNotificationRequests`).
- **`Info.plist` / project.yml:** no special plist key required for local notifications; ensure the capability is not blocked. Background modes already include `workout-processing` (Watch). Add via `project.yml` if any entitlement is needed; none expected for local-only.
- **Scheduling:** `UNCalendarNotificationTrigger` for session (preferred days/time) + milestone (morning); time-interval/calendar for weight + nudge. Payloads carry **no health values** (SECURITY-03).

## 2. Firebase Storage (research export)
- **Module:** `FirebaseStorage` — part of the already-linked Firebase SDK (add the product to the target in `project.yml`; no new remote dependency source).
- **Bucket:** default project bucket.
- **Path:** `users/{uid}/exports/<sessionId>.csv`.
- **Security rules (own-data, SECURITY-02):**
  ```
  rules_version = '2';
  service firebase.storage {
    match /b/{bucket}/o {
      match /users/{uid}/exports/{file=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
      match /{other=**} { allow read, write: if false; }
    }
  }
  ```
  Published by the owner in the Firebase console (like the Firestore rules). **Flagged as a deploy step**, mirroring the Firestore-rules deployment.
- **Upload:** `putData` (resumable); offline-deferred by the SDK; best-effort (non-blocking).

## 3. PDF (PDFKit)
- **Framework:** `PDFKit` (built-in). On-device render; no infra.
- **Output:** a temporary file URL for the share sheet + an optional saved copy in the app's Documents directory (re-openable). Not uploaded anywhere (user-facing, distinct from the research CSV).

## 4. project.yml / build changes
- Add `FirebaseStorage` to the iOS target's dependencies (same SwiftPM Firebase package already used for Auth/Firestore).
- No new entitlements expected; `xcodegen generate` after editing `project.yml`.
- `GoogleService-Info.plist` already present (gitignored) — Storage uses the same config.

## 5. Secrets / config
- No new secrets. Storage uses the existing Firebase app config. SECURITY-04 N/A.

## 6. Deploy checklist (owner actions, flagged)
- [ ] Publish Firebase **Storage security rules** (above) in the console.
- [ ] Confirm the project has a Storage bucket enabled.
- [ ] (Build & Test) grant notification permission on device to verify scheduling.
