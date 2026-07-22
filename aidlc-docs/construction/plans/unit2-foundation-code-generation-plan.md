# Code Generation Plan — Unit 2: iPhone Foundation

## Unit Context

- **Unit**: iPhone Foundation (HeartCoach iOS app target)
- **Location**: `HeartCoach/` at workspace root `/Users/behzad/Heartcoach_v2/`
- **Language**: Swift 5.9, SwiftUI, iOS 17+
- **Dependencies**: HeartRateCoachCore (Unit 1), Firebase iOS SDK 11.x
- **Stories covered**: US-01, US-02, US-03, US-04, US-05, US-19, US-20
- **Depends on**: Unit 1 (HeartRateCoachCore)
- **Required by**: Unit 3 (iPhone Workout Engine), Unit 4 (Apple Watch App)

## Xcode Project Approach
Unit 2 generates a `project.yml` for **XcodeGen** — a widely-used open-source tool that creates `.xcodeproj` files from a simple config file. This avoids manually editing the complex binary `project.pbxproj` format.

**One-time developer setup** (before generating code):
```bash
brew install xcodegen
```
After all Swift files are generated, run `xcodegen generate` in the workspace root to create `HeartCoach.xcodeproj`.

## Design Sources
- `aidlc-docs/construction/unit2-iphone-foundation/functional-design/`
- `aidlc-docs/construction/unit2-iphone-foundation/nfr-design/`
- `aidlc-docs/construction/unit2-iphone-foundation/infrastructure-design/`

---

## Directory Structure

```
HeartCoach/
  App/
    HeartCoachApp.swift
    AppContainer.swift
  Auth/
    AppleSignInNonceGenerator.swift
    FirebaseAuthService.swift
  Firebase/
    AppError.swift
    FirestoreService.swift
  HealthKit/
    HealthKitService.swift
  Offline/
    NetworkMonitor.swift
    CoreDataOfflineQueue.swift
    OfflineQueue.xcdatamodeld/
  ViewModels/
    AuthViewModel.swift
    OnboardingViewModel.swift
    HomeViewModel.swift
    SettingsViewModel.swift
  Views/
    Root/
      RootView.swift
      LoadingView.swift
    Auth/
      SignInView.swift
    Onboarding/
      OnboardingContainerView.swift
      PhysiologicalDataView.swift
      OptionalDetailsView.swift
      PreferencesView.swift
      ZonePreviewView.swift
    Home/
      HomeView.swift
      ZoneCardView.swift
      LastSessionCardView.swift
    History/
      HistoryPlaceholderView.swift
    Settings/
      SettingsView.swift
      ZoneDetailView.swift
    Components/
      ZoneRowView.swift
HeartCoachTests/
  Mocks/
    MockFirebaseService.swift
    MockAuthService.swift
    MockHealthKitService.swift
  AuthViewModelTests.swift
  OnboardingViewModelTests.swift
  HomeViewModelTests.swift
project.yml                     ← XcodeGen config
```

---

## Generation Checklist

### Phase 1: Project Config

- [x] **Step 1** — Create `project.yml` (XcodeGen config)
  - iPhone app target `HeartCoach` (iOS 17+, bundle ID `com.behzad.heartcoach`)
  - Test target `HeartCoachTests`
  - HeartRateCoachCore local SPM package dependency
  - Firebase iOS SDK SPM dependency (`FirebaseAuth`, `FirebaseFirestore`)
  - Capabilities: HealthKit, Sign in with Apple

- [x] **Step 2** — Create directory structure (all folders above)

---

### Phase 2: App Entry + Composition Root

- [x] **Step 3** — Create `HeartCoach/App/HeartCoachApp.swift`
  - `@main` entry point
  - `FirebaseApp.configure()`
  - Firestore `PersistentCacheSettings`
  - `AppContainer` injected into environment

- [x] **Step 4** — Create `HeartCoach/App/AppContainer.swift`
  - `@Observable final class AppContainer`
  - Creates and holds all 4 service instances
  - Constructor injection of services into ViewModels

---

### Phase 3: Error Types

- [x] **Step 5** — Create `HeartCoach/Firebase/AppError.swift`
  - `enum AppError: Error` with all cases
  - `LocalizedDescription` extension with user-facing strings

---

### Phase 4: Auth Layer

- [x] **Step 6** — Create `HeartCoach/Auth/AppleSignInNonceGenerator.swift`
  - `generateRawNonce() -> String`
  - `sha256(_ input: String) -> String`

- [x] **Step 7** — Create `HeartCoach/Auth/FirebaseAuthService.swift`
  - Implements `AuthServiceProtocol`
  - `signInWithApple()` — nonce → Apple credential → Firebase sign-in
  - `signOut()`
  - `authStateStream() -> AsyncStream<String?>`

---

### Phase 5: Firebase Layer

- [x] **Step 8** — Create `HeartCoach/Firebase/FirestoreService.swift`
  - Implements `FirebaseServiceProtocol`
  - `saveProfile(_:zones:userID:)`
  - `loadProfile(userID:) -> UserProfile?`
  - `loadZones(userID:) -> HRZones?`
  - `saveSession(_:userID:)`
  - `loadSessions(userID:limit:) -> [Session]` — `limit: Int = 1` for Home
  - `syncPendingSessions(userID:)` — drains Core Data queue
  - Firestore path constants
  - Firebase error → `AppError` mapping in all catch blocks

---

### Phase 6: HealthKit Layer

- [x] **Step 9** — Create `HeartCoach/HealthKit/HealthKitService.swift`
  - Implements `HealthKitServiceProtocol`
  - `isAuthorized: Bool`
  - `requestAuthorization() async throws`

---

### Phase 7: Offline Layer

- [x] **Step 10** — Create `HeartCoach/Offline/NetworkMonitor.swift`
  - `NWPathMonitor` wrapper
  - `isConnectedStream: AsyncStream<Bool>`
  - `isCurrentlyConnected: Bool`

- [x] **Step 11** — Create `HeartCoach/Offline/OfflineQueue.xcdatamodeld`
  - `PendingSession` entity: `id` (String), `payload` (Binary Data), `createdAt` (Date)

- [x] **Step 12** — Create `HeartCoach/Offline/CoreDataOfflineQueue.swift`
  - Implements `OfflineSessionQueueProtocol`
  - `NSPersistentContainer(name: "OfflineQueue")`
  - `enqueue(_:)`, `pendingSessions()`, `markSynced(id:)`
  - `NSFileProtectionComplete` on store URL

---

### Phase 8: ViewModels

- [x] **Step 13** — Create `HeartCoach/ViewModels/AuthViewModel.swift`
  - `@Observable` — `appState`, `errorMessage`, `isLoading`
  - `checkAuthState()`, `signInWithApple()`, `signOut()`

- [x] **Step 14** — Create `HeartCoach/ViewModels/OnboardingViewModel.swift`
  - `@Observable` — `currentStep`, `draft`, `computedZones`, `rhrWarning`, `fieldError`, `isSaving`
  - `advanceStep()`, `goBack()`, `saveProfile()`
  - Calls `ZoneCalculator.calculate()` on Step 1 validation

- [x] **Step 15** — Create `HeartCoach/ViewModels/HomeViewModel.swift`
  - `@Observable` — `profile`, `zones`, `lastSession`, `isLoading`, `isHealthKitAuthorized`
  - `loadData()`, `recheckHealthKitStatus()`

- [x] **Step 16** — Create `HeartCoach/ViewModels/SettingsViewModel.swift`
  - `@Observable` — `draft`, `computedZones`, `rhrWarning`, `fieldError`, `isSaving`, `saveSuccess`
  - `previewZones()`, `save()`, `signOut()`

---

### Phase 9: Root & Auth Views

- [x] **Step 17** — Create `HeartCoach/Views/Root/RootView.swift`
  - Switches on `authViewModel.appState`
  - Animated transitions between states

- [x] **Step 18** — Create `HeartCoach/Views/Root/LoadingView.swift`
  - App logo + `ProgressView` spinner

- [x] **Step 19** — Create `HeartCoach/Views/Auth/SignInView.swift`
  - `SignInWithAppleButton`
  - Error message display
  - `accessibilityIdentifier("signin-apple-button")`

---

### Phase 10: Onboarding Views

- [x] **Step 20** — Create `HeartCoach/Views/Onboarding/OnboardingContainerView.swift`
  - `NavigationStack` driven by `currentStep`
  - Progress indicator (●○○○ through ●●●●)

- [x] **Step 21** — Create `HeartCoach/Views/Onboarding/PhysiologicalDataView.swift`
  - Age + RHR text fields
  - HealthKit authorization button
  - `RHRWarning` banner
  - Inline `fieldError`
  - `accessibilityIdentifier` on all interactive elements

- [x] **Step 22** — Create `HeartCoach/Views/Onboarding/OptionalDetailsView.swift`
  - Sex picker + weight field
  - Skip + Next buttons

- [x] **Step 23** — Create `HeartCoach/Views/Onboarding/PreferencesView.swift`
  - Goal picker + workout type picker

- [x] **Step 24** — Create `HeartCoach/Views/Onboarding/ZonePreviewView.swift`
  - Computed zone list using `ZoneRowView`
  - "Start Training" button — triggers `saveProfile()`
  - `ProgressView` while `isSaving`

---

### Phase 11: Main App Views

- [x] **Step 25** — Create `HeartCoach/Views/MainTabView.swift`
  - `TabView` with 3 tabs: Home / History / Settings

- [x] **Step 26** — Create `HeartCoach/Views/Home/HomeView.swift`
  - Greeting header
  - `ZoneCardView` (empty state) or `LastSessionCardView` (has sessions)
  - Start Workout button (disabled with instructions if HealthKit denied)
  - Observes `scenePhase` to recheck HealthKit status
  - `accessibilityIdentifier("home-start-workout")`

- [x] **Step 27** — Create `HeartCoach/Views/Home/ZoneCardView.swift`
  - Shows all 5 zones using `ZoneRowView`
  - "View all zones →" link to `ZoneDetailView`

- [x] **Step 28** — Create `HeartCoach/Views/Home/LastSessionCardView.swift`
  - Date, duration, avgHR, time-in-zones bar

- [x] **Step 29** — Create `HeartCoach/Views/History/HistoryPlaceholderView.swift`
  - "Workout history coming soon" placeholder

- [x] **Step 30** — Create `HeartCoach/Views/Settings/SettingsView.swift`
  - Editable profile form
  - Live zone preview (calls `previewZones()`)
  - Save button + Sign Out button
  - `accessibilityIdentifier` on all interactive elements

- [x] **Step 31** — Create `HeartCoach/Views/Settings/ZoneDetailView.swift`
  - Full 5-zone breakdown with descriptions

- [x] **Step 32** — Create `HeartCoach/Views/Components/ZoneRowView.swift`
  - Reusable row: zone number, name, bpm range, colour indicator

---

### Phase 12: Tests

- [x] **Step 33** — Create `HeartCoachTests/Mocks/` — 3 mock service files
  - `MockFirebaseService.swift` — implements `FirebaseServiceProtocol`; returns configurable data
  - `MockAuthService.swift` — implements `AuthServiceProtocol`
  - `MockHealthKitService.swift` — implements `HealthKitServiceProtocol`

- [x] **Step 34** — Create `HeartCoachTests/AuthViewModelTests.swift`
  - Sign-in success → appState = .main
  - Sign-in failure → errorMessage set
  - No profile → appState = .onboarding

- [x] **Step 35** — Create `HeartCoachTests/OnboardingViewModelTests.swift`
  - Step 1 invalid age → fieldError
  - Step 1 valid → computedZones populated, advances to step 2
  - RHR warning range → rhrWarning set but zones computed
  - Save profile → isSaving → success → (delegate appState change)

- [x] **Step 36** — Create `HeartCoachTests/HomeViewModelTests.swift`
  - No sessions → lastSession is nil
  - Has sessions → lastSession populated
  - HealthKit denied → isHealthKitAuthorized = false

---

### Phase 13: Documentation

- [x] **Step 37** — Create `aidlc-docs/construction/unit2-iphone-foundation/code/code-summary.md`

---

## Total: 37 steps across 13 phases

| Phase | Steps | Contents |
|---|---|---|
| 1 — Project Config | 1–2 | project.yml (XcodeGen) + directories |
| 2 — App Entry | 3–4 | HeartCoachApp, AppContainer |
| 3 — Error Types | 5 | AppError |
| 4 — Auth Layer | 6–7 | NonceGenerator, FirebaseAuthService |
| 5 — Firebase Layer | 8 | FirestoreService |
| 6 — HealthKit Layer | 9 | HealthKitService |
| 7 — Offline Layer | 10–12 | NetworkMonitor, Core Data model, CoreDataOfflineQueue |
| 8 — ViewModels | 13–16 | Auth, Onboarding, Home, Settings ViewModels |
| 9 — Root & Auth Views | 17–19 | RootView, LoadingView, SignInView |
| 10 — Onboarding Views | 20–24 | Container + 4 wizard steps |
| 11 — Main App Views | 25–32 | TabView, Home (3 files), History, Settings (2 files), ZoneRow |
| 12 — Tests | 33–36 | 3 mocks + 3 test files |
| 13 — Documentation | 37 | code-summary.md |
