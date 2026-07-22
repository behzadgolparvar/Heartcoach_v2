# Deployment Architecture — Unit 2: iPhone Foundation

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      iPhone (iOS 17+)                       │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   HeartCoach App                    │   │
│  │                                                     │   │
│  │  SwiftUI Views ←→ ViewModels (@Observable)          │   │
│  │       ↓                  ↓                          │   │
│  │  AuthViewModel    OnboardingViewModel                │   │
│  │  HomeViewModel    SettingsViewModel                  │   │
│  │       ↓                  ↓                          │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │              AppContainer                    │   │   │
│  │  │  FirebaseAuthService  FirestoreService       │   │   │
│  │  │  HealthKitService     CoreDataOfflineQueue   │   │   │
│  │  │  NetworkMonitor                              │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │       ↓              ↓              ↓                │   │
│  │  Firebase SDK    HealthKit      Core Data            │   │
│  │  (Auth+Firestore)  (read HR)  (offline queue)       │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                  │
└──────────────────────────┼──────────────────────────────────┘
                           │ HTTPS (Firebase SDK)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  Google Cloud (Firebase)                     │
│                                                             │
│  Firebase Auth ──────── Firestore                           │
│  (Apple Sign-In)        users/{uid}/                        │
│                           profile, zones                    │
│                         users/{uid}/sessions/               │
│                           {sessionId}                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow: App Launch

```
1. HeartCoachApp (@main) initialises AppContainer
2. FirestoreSettings → PersistentCacheSettings enabled
3. Firebase.configure() loads GoogleService-Info.plist
4. AuthViewModel.checkAuthState() subscribes to authStateStream()
5. Firebase Auth emits current user (or nil)
   ├── nil → appState = .signedOut → SignInView
   └── uid → FirestoreService.loadProfile(uid)
                ├── cache hit  → profile returned < 200ms → appState = .main
                ├── network fetch → profile returned < 2s → appState = .main
                └── nil        → appState = .onboarding → OnboardingContainerView
```

---

## Data Flow: Sign in with Apple

```
1. User taps "Sign in with Apple"
2. AppleSignInNonceGenerator.generateRawNonce()
3. sha256(rawNonce) → hashedNonce passed to ASAuthorizationAppleIDRequest
4. iOS presents Apple sign-in sheet
5. User authenticates with Face ID / Touch ID
6. Apple returns ASAuthorizationAppleIDCredential (contains identityToken)
7. OAuthProvider.credential(identityToken, rawNonce) → Firebase credential
8. Auth.auth().signIn(with: credential) → Firebase ID token issued
9. Firebase Auth session persisted locally
10. authStateStream() emits userID → app navigates to onboarding or main
```

---

## Data Flow: Profile Save (Onboarding + Settings)

```
1. ViewModel validates age + RHR (ZoneCalculator.calculate() — Unit 1)
2. Build UserProfile struct
3. FirestoreService.saveProfile(profile, zones:, userID:)
   └── Firestore.document("users/{uid}").setData({
         "profile": { age, restingHR, sex?, weight?, goal, preferredWorkout },
         "zones":   { zone1..zone5 with min/max/name },
         "updatedAt": serverTimestamp()
       }, merge: true)
4. Firestore SDK:
   ├── online  → write to server immediately; cache updated
   └── offline → write queued in Firestore SDK cache; auto-syncs on reconnect
```

---

## Data Flow: Session Write (Offline Queue)

```
Workout ends (Unit 3 delivers Session to FirestoreService)
   │
   ├── NetworkMonitor.isCurrentlyConnected == true
   │     └── FirestoreService.saveSession(session, userID:)
   │           └── Firestore.collection("users/{uid}/sessions").addDocument(...)
   │
   └── NetworkMonitor.isCurrentlyConnected == false
         └── CoreDataOfflineQueue.enqueue(session)
               └── JSONEncoder().encode(session) → PendingSession.payload (Core Data)

Network reconnects (NWPathMonitor fires):
   └── FirestoreService.syncPendingSessions()
         ├── CoreDataOfflineQueue.pendingSessions() → [Session]
         └── for each session:
               ├── FirestoreService.saveSession(session, userID:)
               └── CoreDataOfflineQueue.markSynced(id:) → deleted from Core Data
```

---

## Deployment Path

```
Development
  Xcode (Debug build) → run on iPhone via USB or wireless
  GoogleService-Info.plist (single Firebase project)

Testing
  Xcode → Archive → TestFlight upload
  Testers install via TestFlight
  Crash logs: Xcode Organizer (no Crashlytics in v1)

Production
  Xcode → Archive → App Store Connect → App Store
  Same Firebase project as development (single project — Q1 decision)
```

---

## Firebase SDK Initialisation (Code Reference)

```swift
// HeartCoachApp.swift (@main)
import Firebase

@main
struct HeartCoachApp: App {
    init() {
        FirebaseApp.configure()

        // Enable Firestore offline persistence
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AppContainer())
        }
    }
}
```

---

## Infrastructure Not Used in v1

| Service | Reason skipped |
|---|---|
| Firebase Crashlytics | Added post-v1 when TestFlight users join (Q2 — B) |
| Firebase Analytics | No analytics needed for personal training app |
| Firebase Cloud Functions | No server-side logic required |
| Firebase Remote Config | No feature flags needed |
| Firebase Storage | No file uploads (no profile photos in v1) |
| Push Notifications (APNs) | No notifications in v1 |
