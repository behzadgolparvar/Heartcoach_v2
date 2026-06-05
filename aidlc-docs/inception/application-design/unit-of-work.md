# Units of Work — HeartRateCoach

## Project Setup
- **Xcode project**: Hand-crafted `.xcodeproj` — managed directly in Xcode GUI
- **Shared code**: Local SPM package (`HeartRateCoachCore`) — added to workspace as a local package
- **Build sequence**: Unit 1 → Unit 2 → Unit 3 → Unit 4
- **Parallelisation**: Unit 4 (Watch) can begin after Unit 1 is complete; no dependency on Unit 3

---

## Unit 1 — HeartRateCoachCore (SPM Package)

**Type**: Local Swift Package  
**Target**: Pure Swift — iOS 17+ / watchOS 10+ (shared)  
**Directory**: `HeartRateCoachCore/` at workspace root

### Responsibility
Pure domain layer — models, zone calculation logic, and workout program definitions. No UIKit, SwiftUI, HealthKit, Firebase, or WatchConnectivity dependencies. Fully unit-testable without a device.

### Contents

| Component | Type | Description |
|---|---|---|
| `UserProfile` | struct | Age, RHR, sex, weight, goal, preferredWorkout |
| `HRZones` | struct | Five zone boundaries (min/max bpm per zone) |
| `Zone` | struct | Single zone with min, max, number, name |
| `WorkoutProgram` | enum | .continuous, .hiit, .fartlek — each provides phase sequence |
| `WorkoutPhase` | struct | Duration, targetZone, phaseType, hasGracePeriod |
| `PhaseType` | enum | .warmup, .exercise, .recovery, .cooldown |
| `Session` | struct | Completed workout record |
| `HRRecord` | struct | Single HR time-series data point |
| `CoachingState` | struct | Current HR, zone, phase, message — published to UI |
| `CoachingCommand` | enum | .haptic(HapticPattern), .emergencyStop |
| `HapticPattern` | enum | .short, .long, .doubleTap, .emergencyRepeated |
| `HRReading` | struct | HR value + timestamp from Watch sensor |
| `SyncStatus` | enum | .synced, .savedLocally, .syncing |
| `ZoneCalculator` | struct (static) | Karvonen formula — zone calculation + HR classification |
| `WorkoutPhaseSequencer` | struct | Iterates program phases by elapsed time |

### Xcode File Structure
```
HeartRateCoachCore/
  Sources/
    HeartRateCoachCore/
      Models/
        UserProfile.swift
        HRZones.swift
        WorkoutProgram.swift
        WorkoutPhase.swift
        Session.swift
        HRRecord.swift
        CoachingState.swift
        CoachingCommand.swift
        HRReading.swift
        SyncStatus.swift
      Engine/
        ZoneCalculator.swift
        WorkoutPhaseSequencer.swift
  Tests/
    HeartRateCoachCoreTests/
      ZoneCalculatorTests.swift        // PBT + example-based
      WorkoutPhaseSequencerTests.swift
```

### Milestone
After Unit 1: all domain models and zone calculation logic are complete and tested. No app UI exists yet.

---

## Unit 2 — iPhone Foundation

**Type**: iPhone App Target (primary target)  
**Target**: iOS 17+  
**Directory**: `HeartRateCoach/` at workspace root

### Responsibility
The app skeleton — authentication, onboarding, settings, HR zone display, and the Home screen (with stubbed Start button). After this unit, the app is fully runnable on a device with real Firebase auth and profile persistence.

### Contents

| Component | Layer | Description |
|---|---|---|
| `HeartRateCoachApp.swift` | App | App entry point; creates AppContainer |
| `AppContainer.swift` | DI | Composition root — creates all services, injects into ViewModels |
| `AuthService` | Service | Firebase Auth + Sign in with Apple |
| `FirebaseService` | Service | Firestore profile, zones, settings read/write |
| `HealthKitService` | Service | HealthKit authorization request |
| `OfflineSessionQueue` | Service | Core Data queue for offline session persistence |
| `OnboardingViewModel` | ViewModel | Onboarding flow state + validation |
| `SettingsViewModel` | ViewModel | Settings screen state + zone recalculation |
| `ZoneDisplayViewModel` | ViewModel | HR zone formatting for display |
| `HomeViewModel` | ViewModel | Home screen — last session summary, workout selector, stubbed start action |
| `OnboardingView` | View | Multi-step onboarding (age, RHR, goal, preferred workout) |
| `ZoneDisplayView` | View | 5-zone HR range display |
| `HomeView` | View | Workout selector, last session snippet, Start button (stubbed) |
| `SettingsView` | View | Profile + goal + preferred workout editing |

### Xcode File Structure
```
HeartRateCoach/
  App/
    HeartRateCoachApp.swift
    AppContainer.swift
  Services/
    AuthService.swift
    FirebaseService.swift
    HealthKitService.swift
    OfflineSessionQueue.swift
  ViewModels/
    OnboardingViewModel.swift
    SettingsViewModel.swift
    ZoneDisplayViewModel.swift
    HomeViewModel.swift
  Views/
    Onboarding/
      OnboardingView.swift
      ZoneDisplayView.swift
    Home/
      HomeView.swift
    Settings/
      SettingsView.swift
  Resources/
    Assets.xcassets
    GoogleService-Info.plist   // excluded from git
```

### Milestone
After Unit 2: app launches on device → Sign in with Apple → Onboarding → Home (Start stubbed) → Settings. Firebase profile and zone data persists correctly.

---

## Unit 3 — iPhone Workout Engine

**Type**: Additional source files in iPhone App Target  
**Target**: iOS 17+  
**Directory**: additional files within `HeartRateCoach/`

### Responsibility
The complete workout experience — coaching engine, Watch communication, live workout UI, session persistence, history, and session summary. Also wires up the Home screen Start button (replaces Unit 2 stub).

### Contents

| Component | Layer | Description |
|---|---|---|
| `SafetyMonitor` | Engine | Layer 1 — HR > HRmax detection |
| `ZoneCoach` | Engine | Layer 2 — zone feedback + anti-spam (20 sec) |
| `PositiveFeedbackCoach` | Engine | Layer 3 — 30s in-zone positive feedback |
| `CoachingEngine` | Engine | Orchestrates all 3 layers; per-session instance |
| `VoiceFeedbackService` | Service | AVSpeechSynthesizer wrapper |
| `WatchBridge` | Service | WatchConnectivity iPhone side — HR in, haptics out |
| `WorkoutSessionManager` | Service | Workout lifecycle; Firebase writes; offline fallback |
| `WorkoutViewModel` | ViewModel | Live workout screen state |
| `SessionSummaryViewModel` | ViewModel | Post-workout summary formatting |
| `HistoryViewModel` | ViewModel | Past sessions list from Firestore |
| `WorkoutView` | View | Live HR, zone, phase timer, coaching message |
| `SessionSummaryView` | View | Time-in-zones, avg HR, duration |
| `HistoryView` | View | Chronological session list |
| `HomeViewModel` (update) | ViewModel | Start button wired to WorkoutSessionManager |

### Xcode File Structure (additions to HeartRateCoach/)
```
HeartRateCoach/
  Engine/
    SafetyMonitor.swift
    ZoneCoach.swift
    PositiveFeedbackCoach.swift
    CoachingEngine.swift
  Services/
    VoiceFeedbackService.swift
    WatchBridge.swift
    WorkoutSessionManager.swift
  ViewModels/
    WorkoutViewModel.swift
    SessionSummaryViewModel.swift
    HistoryViewModel.swift
  Views/
    Workout/
      WorkoutView.swift
    Summary/
      SessionSummaryView.swift
    History/
      HistoryView.swift
```

### Milestone
After Unit 3: complete iPhone app. User can start any of the 3 workouts, receive voice coaching, complete session, view summary, and browse history. Offline session queuing works. Watch haptics are sent but Watch app not yet built.

---

## Unit 4 — Apple Watch App

**Type**: watchOS App Target  
**Target**: watchOS 10+  
**Directory**: `HeartRateCoachWatch/` at workspace root

### Responsibility
The complete Watch experience — HKWorkoutSession for live HR, WatchConnectivity to iPhone, haptic execution, and all three Watch screens.

### Contents

| Component | Layer | Description |
|---|---|---|
| `WatchApp.swift` | App | Watch app entry point |
| `WatchSessionManager` | Service | HKWorkoutSession — starts/stops, reads HR from sensor |
| `WatchConnectivityManager` | Service | Sends HR to iPhone; receives coaching commands |
| `HapticManager` | Service | Executes WKHapticType patterns |
| `WorkoutWatchViewModel` | ViewModel | Watch screen state — HR, zone, phase, overlays |
| `WorkoutWatchView` | View | Live HR, current zone, target zone, phase indicator |
| `CoachingOverlayView` | View | Zone transition announcement (3-sec overlay) |
| `EmergencyView` | View | Full-screen HR > HRmax warning |

### Xcode File Structure
```
HeartRateCoachWatch/
  App/
    WatchApp.swift
  Services/
    WatchSessionManager.swift
    WatchConnectivityManager.swift
    HapticManager.swift
  ViewModels/
    WorkoutWatchViewModel.swift
  Views/
    WorkoutWatchView.swift
    CoachingOverlayView.swift
    EmergencyView.swift
```

### Milestone
After Unit 4: complete app. Watch displays live HR and zone, coaching overlay fires on transitions, emergency stop shows full-screen warning, haptics execute correctly.

---

## Build Sequence Summary

```
Unit 1: HeartRateCoachCore (SPM)
  |
  +---> Unit 2: iPhone Foundation
  |       |
  |       +---> Unit 3: iPhone Workout Engine
  |
  +---> Unit 4: Apple Watch App
        (can start after Unit 1; no dependency on Unit 3)
```

| Unit | Depends On | Can Parallelise With |
|---|---|---|
| 1 — Core | — | Nothing (must be first) |
| 2 — iPhone Foundation | Unit 1 | — |
| 3 — iPhone Workout Engine | Units 1 + 2 | Unit 4 |
| 4 — Apple Watch App | Unit 1 | Unit 3 |
