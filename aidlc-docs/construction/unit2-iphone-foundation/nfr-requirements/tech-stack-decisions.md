# Tech Stack Decisions — Unit 2: iPhone Foundation

## Language & Platform

| Decision | Choice | Rationale |
|---|---|---|
| Swift version | Swift 5.9 | Consistent with Unit 1; `@Observable` available |
| Minimum deployment | iOS 17.0 | Project-wide target; `@Observable` requires iOS 17 |
| UI framework | SwiftUI | Project-wide decision from INCEPTION |

---

## Firebase

| Decision | Choice | Rationale |
|---|---|---|
| Firebase iOS SDK | via SPM, `from: "11.0.0"` | Latest stable major version; SPM native |
| Products used | `FirebaseAuth`, `FirebaseFirestore` | Auth + Firestore only; no Analytics, no Crashlytics in v1 |
| Offline persistence | `PersistentCacheSettings` — enabled | Profile + zones served from cache when offline (Q2 — A) |
| Session loading on Home | `.limit(to: 1)` query | Only most recent session needed for Home card (Q4 — A) |

### Package.swift addition (iPhone app target)
```swift
.package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")

// In target dependencies:
.product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
.product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
```

### Firestore offline setup (AppContainer init)
```swift
let settings = FirestoreSettings()
settings.cacheSettings = PersistentCacheSettings()
Firestore.firestore().settings = settings
```

---

## Firestore Security Rules

Deployed to Firebase console before production use. Owner (Behzad) deploys via Firebase CLI.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // User document and all subcollections — owner-only access
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      match /sessions/{sessionId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }

    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Apple Frameworks (No SPM — system frameworks)

| Framework | Purpose | Notes |
|---|---|---|
| `AuthenticationServices` | Sign in with Apple credential | `ASAuthorizationAppleIDProvider` |
| `HealthKit` | HR read authorization | `HKHealthStore`, `HKQuantityTypeIdentifier.heartRate` |
| `CoreData` | Offline session queue persistence | `NSPersistentContainer` |
| `Network` | Connectivity monitoring | `NWPathMonitor` for reconnect detection |
| `UIKit` | Settings deep-link | `UIApplication.open(URL(string: UIApplication.openSettingsURLString)!)` |

---

## Secrets Management

| Item | Rule |
|---|---|
| `GoogleService-Info.plist` | NOT committed to git — added to `.gitignore` |
| Distribution | Shared via secure channel between developers |
| Firebase project | Single project for v1 (no dev/prod split) |

### .gitignore entry
```
GoogleService-Info.plist
```

---

## Dependency Summary

| Dependency | Type | Version | Scope |
|---|---|---|---|
| Firebase iOS SDK | SPM | from: "11.0.0" | Production |
| FirebaseAuth | Firebase product | — | Production |
| FirebaseFirestore | Firebase product | — | Production |
| AuthenticationServices | Apple framework | iOS 17+ | Production |
| HealthKit | Apple framework | iOS 17+ | Production |
| CoreData | Apple framework | iOS 17+ | Production |
| Network | Apple framework | iOS 17+ | Production |

---

## Security Compliance Summary (Unit 2)

| Rule | Status | Notes |
|---|---|---|
| SECURITY-01 | Compliant | Firestore encrypted at rest by Google; Core Data protected by iOS file protection |
| SECURITY-02 | N/A | Firebase audit logging available on paid tier — not configured for v1 |
| SECURITY-03 | Planned | Health data excluded from all logging — enforced by logging conventions |
| SECURITY-04 | N/A | No web/HTTP layer |
| SECURITY-05 | Compliant | ZoneCalculator validates all profile inputs; Firestore rules validate structure |
| SECURITY-06 | Compliant | Firebase security rules: owner-only access to `users/{userId}` |
| SECURITY-07 | Compliant | Firebase SDK uses HTTPS; ATS enabled; no cleartext exceptions |
| SECURITY-08 | Compliant | Firebase Auth manages token lifecycle; no manual token storage |
| SECURITY-09 | Compliant | `GoogleService-Info.plist` in `.gitignore` |
| SECURITY-10 | Compliant | Firebase SDK via SPM with major-version pin; `Package.resolved` committed |
| SECURITY-11 | Compliant | Health data under `users/{userId}` — access controlled; never sent to third parties |
| SECURITY-12 | Compliant | Sign in with Apple → Firebase ID token; SDK manages refresh |
| SECURITY-13 | Compliant | Firestore security rules validate document ownership |
| SECURITY-14 | N/A | No deployed service monitoring needed for v1 |
| SECURITY-15 | Planned | Firebase errors mapped to generic user-facing messages; no raw error exposure |
