# Infrastructure Design — Unit 2: iPhone Foundation

---

## Infrastructure Overview

HeartRateCoach uses a minimal cloud footprint — one Firebase project (Google Cloud) handles all backend needs. All compute runs on-device. There are no custom servers, no API gateways, and no message queues.

---

## Cloud Infrastructure — Firebase (Google Cloud)

### Firebase Project

| Property | Value |
|---|---|
| Project name | `heartcoach` (to be created in Firebase console) |
| Environment | Single project — development + production (Q1 — A) |
| Region | `us-central1` (Firestore default; change to `europe-west1` if user is primarily in Europe) |
| Google account | behzad.golparvar1991@gmail.com |

### Firebase Services Used

| Service | Purpose | Plan |
|---|---|---|
| Firebase Authentication | Sign in with Apple → Firebase ID token | Spark (free) |
| Cloud Firestore | User profile, zones, session history | Spark (free up to 1 GiB storage, 50K reads/day) |
| Firebase Crashlytics | **Not used in v1** (Q2 — B) | N/A |
| Firebase Analytics | **Not used in v1** | N/A |

### Firestore Configuration

| Property | Value |
|---|---|
| Mode | Native mode (not Datastore mode) |
| Offline persistence | Enabled — `PersistentCacheSettings` |
| Security rules | Owner-only (see below) |
| Indexes | None required for v1 queries |

### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
      match /sessions/{sessionId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## On-Device Infrastructure (Apple)

| Component | Technology | Purpose |
|---|---|---|
| Offline session queue | Core Data (`NSPersistentContainer`) | Stores pending sessions as JSON blobs until Firebase is reachable |
| Health data access | HealthKit (`HKHealthStore`) | HR read authorization — used by Unit 4 Watch app for live HR |
| Network monitoring | `NWPathMonitor` (Network framework) | Detects connectivity changes; triggers offline queue sync |
| Local file protection | iOS Data Protection (`NSFileProtectionComplete`) | Core Data store encrypted while device is locked |

---

## Shared Infrastructure (All Units)

The same Firebase project is shared by Unit 2 (iPhone Foundation), Unit 3 (iPhone Workout Engine), and Unit 4 (Apple Watch App). There is no per-unit Firebase configuration.

| Unit | Firebase services used |
|---|---|
| Unit 2 — iPhone Foundation | Auth, Firestore (profile/zones/sessions) |
| Unit 3 — iPhone Workout Engine | Firestore (session writes, history reads) |
| Unit 4 — Apple Watch App | None directly — Watch communicates via WatchConnectivity to iPhone |

---

## Manual Setup Checklist (Developer Actions Required)

These steps must be performed manually in the Firebase console and Xcode before Unit 2 code will run:

- [ ] Create Firebase project `heartcoach` at console.firebase.google.com
- [ ] Enable Authentication → Sign-in method → Apple
- [ ] Create Firestore database in Native mode (region: `us-central1`)
- [ ] Deploy security rules (copy from above)
- [ ] Register iOS app bundle ID in Firebase project
- [ ] Download `GoogleService-Info.plist` → add to Xcode project (do NOT commit to git)
- [ ] Add `GoogleService-Info.plist` to `.gitignore`
- [ ] Configure Sign in with Apple in Apple Developer portal:
  - Enable "Sign in with Apple" capability for the app ID
  - Register the Service ID if needed by Firebase
- [ ] Add Firebase SDK to Xcode project via SPM

---

## Cost Estimate (Spark Free Tier)

| Resource | Free tier limit | Expected v1 usage |
|---|---|---|
| Firestore reads | 50,000 / day | < 100 / day (1 user) |
| Firestore writes | 20,000 / day | < 50 / day |
| Firestore storage | 1 GiB | < 10 MB (profile + ~100 sessions) |
| Auth monthly active users | Unlimited on Spark | 1 |

**Conclusion**: Spark free tier is sufficient for v1 with a single user. No billing required.
