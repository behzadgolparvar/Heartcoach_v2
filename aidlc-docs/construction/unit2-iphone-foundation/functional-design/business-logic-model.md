# Business Logic Model — Unit 2: iPhone Foundation

---

## 1. App Startup Flow

```
App launches
  │
  ├── AppContainer created (singleton)
  │     └── all services instantiated with constructor injection
  │
  └── AuthViewModel.checkAuthState()
        │
        ├── appState = .loading
        │
        └── authService.authStateStream() emits:
              │
              ├── nil (no user) → appState = .signedOut
              │
              └── userID → firebaseService.loadProfile(userID:)
                    │
                    ├── profile found → appState = .main
                    └── profile nil  → appState = .onboarding
```

---

## 2. Authentication Flow (Sign in with Apple)

```
User taps "Sign in with Apple"
  │
  ├── AuthViewModel.signInWithApple()
  │     isLoading = true
  │
  ├── authService.signInWithApple()
  │     └── Apple credential → Firebase Auth → returns userID
  │
  ├── firebaseService.loadProfile(userID:)
  │     │
  │     ├── profile found → appState = .main
  │     └── profile nil   → appState = .onboarding
  │
  └── on error → errorMessage = "Sign in failed. Please try again."
        isLoading = false
```

---

## 3. Onboarding Flow (4-step wizard)

### Step 1 — Physiological Data

```
User enters age + restingHR
  │
  ├── HealthKit authorization requested (if not already granted)
  │     └── healthKitService.requestAuthorization()
  │
  ├── User taps "Next"
  │     │
  │     └── OnboardingViewModel.advanceStep()
  │           │
  │           ├── Validate age (15–100)
  │           │     └── fail → fieldError = "Please enter a valid age (15–100)"
  │           │
  │           ├── Validate restingHR (> 0)
  │           │     └── fail → fieldError = "Please enter a valid resting HR"
  │           │
  │           ├── ZoneCalculator.calculate(age:restingHR:)
  │           │     ├── success → computedZones = zones; rhrWarning = warning
  │           │     └── throws → fieldError = localised error message
  │           │
  │           └── pass → currentStep = .optionalDetails
```

### Step 2 — Optional Details

```
User optionally enters sex + weight
  │
  └── User taps "Next" or "Skip"
        └── currentStep = .preferences
            (no validation — both fields optional)
```

### Step 3 — Preferences

```
User selects goal + preferred workout
  │
  └── User taps "Next"
        └── currentStep = .zonePreview
            (no validation — both fields have defaults)
```

### Step 4 — Zone Preview

```
Display computedZones (calculated in Step 1)
  │
  └── User taps "Start Training"
        │
        └── OnboardingViewModel.saveProfile()
              │
              ├── Build UserProfile from draft
              ├── isSaving = true
              │
              ├── firebaseService.saveProfile(profile, zones:, userID:)
              │     ├── success → appState = .main
              │     └── error   → show retry alert; isSaving = false
              │
              └── isSaving = false
```

---

## 4. Profile Save Flow (Settings)

```
User edits fields on SettingsView
  │
  ├── SettingsViewModel.previewZones() — called as fields change
  │     └── if age + RHR are valid: show live zone preview
  │
  └── User taps "Save"
        │
        └── SettingsViewModel.save()
              │
              ├── Validate age (15–100)
              ├── Validate restingHR (> 0)
              ├── ZoneCalculator.calculate(age:restingHR:) — throws on invalid
              │
              ├── isSaving = true
              ├── firebaseService.saveProfile(profile, zones:, userID:)
              │     ├── success → saveSuccess = true (briefly); zones updated
              │     └── error   → fieldError = "Save failed. Please try again."
              │
              └── isSaving = false
```

---

## 5. Zone Recalculation Trigger

Zone recalculation happens in exactly two places:

| Trigger | Where | When |
|---|---|---|
| Onboarding Step 1 "Next" | `OnboardingViewModel.advanceStep()` | After age + RHR validated |
| Settings "Save" | `SettingsViewModel.save()` | Before Firestore write |

Both call `ZoneCalculator.calculate(age:restingHR:)` and pass the result to `firebaseService.saveProfile(_:zones:userID:)`.

---

## 6. Offline Session Queue Flow

The queue is written by Unit 3 (CoachingEngine) and synced in Unit 2. Defined here for completeness.

```
Network becomes available (NWPathMonitor fires)
  │
  └── FirebaseService.syncPendingSessions(userID:)
        │
        ├── offlineQueue.pendingSessions()
        │
        └── for each pending session:
              ├── firebaseService.saveSession(session, userID:)
              │     ├── success → offlineQueue.markSynced(id:)
              │     └── error   → leave in queue (retry on next reconnect)
              └── repeat
```

---

## 7. Home Screen Content Logic

```
HomeViewModel.loadData()
  │
  ├── firebaseService.loadProfile(userID:) → profile
  ├── firebaseService.loadZones(userID:)   → zones
  └── firebaseService.loadSessions(userID:) → sessions (sorted by date desc)
        │
        └── lastSession = sessions.first  // nil if no sessions yet
```

**HomeView rendering decision:**

```
IF lastSession != nil:
    show LastSessionCard (date, duration, avgHR, zone breakdown)
ELSE:
    show ZoneCard (personalised zone ranges)

ALWAYS show:
    Start Workout button
    User greeting ("Good morning, [name]" or "Welcome!")
```
