# NFR Requirements — Unit 2: iPhone Foundation

## NFR Category Assessment

| Category | Applicable | Reason |
|---|---|---|
| Performance | Yes | Auth flow, Firestore load times, startup speed |
| Security | Yes | Firebase rules, health data privacy, auth tokens, supply chain |
| Reliability | Yes | Offline persistence, offline session queue, network monitoring |
| Availability | Partial | Offline mode via Firestore cache; no self-hosted infrastructure |
| Scalability | N/A | Single-user personal app; no concurrent load concerns |
| Maintainability | Yes | Protocol-backed services, testability |
| Usability | Yes | HealthKit denial UX, error messaging |

---

## Performance Requirements

| Requirement | Target | Rationale |
|---|---|---|
| App cold start to Home screen | < 2 seconds | Auth state check + Firestore cache read must complete quickly |
| Sign in with Apple flow | < 3 seconds | Apple credential + Firebase token exchange |
| Profile + zones load (cached) | < 200ms | Firestore offline cache — returns instantly from disk |
| Profile + zones load (network) | < 2 seconds | First launch or cache miss |
| Home screen `lastSession` load | < 1 second | Single Firestore document read with `.limit(to: 1)` |
| Profile save (Firestore write) | < 2 seconds | Single document write on Settings Save |

---

## Security Requirements

### SECURITY-01: Encryption at Rest
- Firestore data is encrypted at rest by Google infrastructure ✓ (no additional action required)
- Core Data offline queue is stored in the app's sandbox — protected by iOS data protection (`NSFileProtectionComplete`)

### SECURITY-03: Application Logging
- **CRITICAL**: Health data (age, RHR, HR readings, zone values) must NEVER appear in logs, crash reports, or analytics events
- Only log: auth state changes (userID only, no PII), Firestore operation results (success/error code, no document content), offline queue depth

### SECURITY-05: Input Validation
- All profile field validation handled by `ZoneCalculator.calculate()` (Unit 1) before any Firestore write
- Firestore security rules provide server-side validation of data structure (see tech-stack-decisions.md)

### SECURITY-06: Least Privilege — Firebase Security Rules
- Users can ONLY read and write their own documents: `users/{userID}` and `users/{userID}/sessions/{sessionID}`
- No user can read any other user's data
- Unauthenticated requests are rejected entirely
- Firebase security rules defined and deployed before any production use (see tech-stack-decisions.md)

### SECURITY-07: Network Security
- All Firebase communication uses HTTPS/TLS — enforced by Firebase SDK
- No cleartext HTTP permitted — iOS App Transport Security (ATS) remains enabled (no exceptions)

### SECURITY-09: Secrets Handling
- `GoogleService-Info.plist` must NOT be committed to git
- Must be added to `.gitignore` before first commit containing Firebase setup
- Distributed to developers via a secure channel (not the repo)

### SECURITY-10: Supply Chain
- Firebase iOS SDK added via SPM with version range pinned to major version (e.g., `from: "11.0.0"`)
- `Package.resolved` committed to git for reproducible builds
- No other third-party dependencies in Unit 2 beyond Firebase

### SECURITY-11: Health Data Classification
- Age and RHR are health-adjacent personal data
- HR zone data derived from them is also sensitive
- All such data lives in Firestore under `users/{userID}` — access controlled by Firebase security rules
- Data is NEVER sent to third-party analytics, crash reporters, or ad networks

### SECURITY-12: Authentication
- Sign in with Apple is the sole auth method
- Apple credential (identity token) is exchanged for a Firebase ID token via `AuthCredential`
- Firebase ID token is managed entirely by the Firebase Auth SDK — never stored manually by app code
- Token refresh is handled automatically by Firebase SDK
- On sign-out: `Auth.auth().signOut()` invalidates the local session

### SECURITY-15: Exception Handling
- Firebase errors are caught and surfaced to users as generic messages — raw Firebase error codes and messages are NOT shown to users
- Example: Firestore write failure → "Save failed. Please try again." (not the Firebase error string)

---

## Reliability Requirements

| Requirement | Detail |
|---|---|
| Firestore offline persistence | Enabled — `PersistentCacheSettings`; profile + zones load from cache when offline |
| Offline session queue | Core Data queue (manual) for session writes when Firebase is unreachable |
| Network monitoring | `NWPathMonitor` watches connectivity; triggers `syncPendingSessions()` on reconnect |
| Retry policy | Failed session sync retried on next reconnect — no exponential backoff needed for v1 |
| Auth failure recovery | If Firebase auth state is lost, app returns to `.signedOut` state gracefully |

---

## Usability Requirements (HealthKit Denial)

| Scenario | Behaviour |
|---|---|
| HealthKit denied during onboarding | Onboarding completes normally; user reaches Home screen |
| Start Workout button when denied | Button is **disabled** (greyed out) |
| Instruction text below disabled button | "Heart rate access is required to use HeartCoach." |
| Recovery action | Tappable "Open Settings →" link — deep-links to `UIApplication.openSettingsURLString` |
| Recovery after granting in Settings | App detects HealthKit status on next foreground activation; button re-enables automatically |

---

## Firestore Data Schema (Q1 Decision)

```
users/{userID}                    ← single document per user
  profile:
    age: Int
    restingHR: Int
    sex: String?
    weight: Double?
    goal: String
    preferredWorkout: String
    updatedAt: Timestamp
  zones:
    zone1: { min: Int, max: Int, name: String }
    zone2: { min: Int, max: Int, name: String }
    zone3: { min: Int, max: Int, name: String }
    zone4: { min: Int, max: Int, name: String }
    zone5: { min: Int, max: Int, name: String }

users/{userID}/sessions/{sessionID}   ← subcollection
  date: Timestamp
  programType: String
  durationSec: Int
  avgHR: Int
  timeInZones: Map<String, Int>
  hrStream: Array (omitted from Home query — loaded in History tab only)
```
