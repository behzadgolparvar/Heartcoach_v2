# Code Summary — Unit 2: iPhone Foundation

## Generated Files

### Project Config
| File | Purpose |
|---|---|
| `project.yml` | XcodeGen config — run `xcodegen generate` to create `HeartCoach.xcodeproj` |
| `HeartCoach/HeartCoach.entitlements` | HealthKit + Sign in with Apple capabilities |

### App Entry + Composition Root
| File | Purpose |
|---|---|
| `HeartCoach/App/HeartCoachApp.swift` | `@main` — Firebase.configure(), Firestore offline settings, environment injection |
| `HeartCoach/App/AppContainer.swift` | Creates all services + ViewModels; wires onboarding completion callback |

### Auth Layer
| File | Purpose |
|---|---|
| `HeartCoach/Auth/AuthServiceProtocol.swift` | Protocol for auth operations |
| `HeartCoach/Auth/AppleSignInNonceGenerator.swift` | SHA256 nonce generation for Sign in with Apple |
| `HeartCoach/Auth/FirebaseAuthService.swift` | Firebase Auth implementation |

### Firebase Layer
| File | Purpose |
|---|---|
| `HeartCoach/Firebase/AppError.swift` | Typed error enum with user-facing messages |
| `HeartCoach/Firebase/FirebaseServiceProtocol.swift` | Protocol for Firestore operations |
| `HeartCoach/Firebase/FirestoreService.swift` | Firestore CRUD + offline sync trigger |

### HealthKit Layer
| File | Purpose |
|---|---|
| `HeartCoach/HealthKit/HealthKitServiceProtocol.swift` | Protocol for HR authorization |
| `HeartCoach/HealthKit/HealthKitService.swift` | HKHealthStore implementation |

### Offline Layer
| File | Purpose |
|---|---|
| `HeartCoach/Offline/NetworkMonitor.swift` | NWPathMonitor → AsyncStream<Bool> |
| `HeartCoach/Offline/OfflineSessionQueueProtocol.swift` | Protocol for offline queue |
| `HeartCoach/Offline/OfflineQueue.xcdatamodeld` | Core Data model: PendingSession (id, payload, createdAt) |
| `HeartCoach/Offline/CoreDataOfflineQueue.swift` | JSON blob queue implementation |

### ViewModels (all @Observable)
| File | Purpose |
|---|---|
| `HeartCoach/ViewModels/AuthViewModel.swift` | AppState management, Sign in with Apple |
| `HeartCoach/ViewModels/OnboardingViewModel.swift` | 4-step wizard, zone computation, profile save |
| `HeartCoach/ViewModels/HomeViewModel.swift` | Profile/zones/lastSession loading, HealthKit status |
| `HeartCoach/ViewModels/SettingsViewModel.swift` | Profile editing, live zone preview, save |

### Views (SwiftUI, dark mode)
| File | Purpose |
|---|---|
| `Views/Root/RootView.swift` | Switches between states with animation |
| `Views/Root/LoadingView.swift` | Launch splash + spinner |
| `Views/Auth/SignInView.swift` | SignInWithAppleButton + error display |
| `Views/Onboarding/OnboardingContainerView.swift` | NavigationStack + step indicator |
| `Views/Onboarding/PhysiologicalDataView.swift` | Step 1: age, RHR, HealthKit |
| `Views/Onboarding/OptionalDetailsView.swift` | Step 2: sex, weight (skippable) |
| `Views/Onboarding/PreferencesView.swift` | Step 3: goal, workout type |
| `Views/Onboarding/ZonePreviewView.swift` | Step 4: zone display + Start Training |
| `Views/MainTabView.swift` | TabView: Home / History / Settings |
| `Views/Home/HomeView.swift` | Zone card or last session + Start Workout |
| `Views/Home/ZoneCardView.swift` | 5-zone list card for empty state |
| `Views/Home/LastSessionCardView.swift` | Session summary + zone bar |
| `Views/History/HistoryPlaceholderView.swift` | "Coming soon" placeholder |
| `Views/Settings/SettingsView.swift` | Profile form + live preview + Save |
| `Views/Settings/ZoneDetailView.swift` | Full zone breakdown with descriptions |
| `Views/Components/ZoneRowView.swift` | Reusable zone row |
| `Views/Components/ButtonStyles.swift` | PrimaryButtonStyle, SecondaryButtonStyle |
| `Views/Components/Banners.swift` | WarningBanner, ErrorBanner |

### Tests
| File | Purpose |
|---|---|
| `HeartCoachTests/Mocks/MockFirebaseService.swift` | Configurable mock for all Firestore operations |
| `HeartCoachTests/Mocks/MockAuthService.swift` | Configurable mock for auth operations |
| `HeartCoachTests/Mocks/MockHealthKitService.swift` | Configurable mock for HealthKit |
| `HeartCoachTests/AuthViewModelTests.swift` | Auth state transitions, sign-out |
| `HeartCoachTests/OnboardingViewModelTests.swift` | Validation, zone computation, save flows |
| `HeartCoachTests/HomeViewModelTests.swift` | Data loading, HealthKit status |

---

## Stories Covered

| Story | Implementation |
|---|---|
| US-01 Sign in with Apple | `SignInView` + `FirebaseAuthService` |
| US-02 Enter age and RHR | `PhysiologicalDataView` + `OnboardingViewModel` |
| US-03 Select goal + workout | `PreferencesView` |
| US-04 View personalised zones | `ZonePreviewView`, `ZoneCardView`, `ZoneDetailView` |
| US-05 Zones recalculate on change | `SettingsViewModel.updatePreview()` + `save()` |
| US-19 Update profile | `SettingsView` + `SettingsViewModel.save()` |
| US-20 Update goal/workout | `SettingsView` |

---

## Developer Setup (one-time)

```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Generate Xcode project from project.yml
cd /Users/behzad/Heartcoach_v2
xcodegen generate

# 3. Add GoogleService-Info.plist to HeartCoach/ folder in Xcode
#    (do NOT commit this file)

# 4. Open the generated project
open HeartCoach.xcodeproj
```

## Key Implementation Notes

- `AppContainer` wires `onboardingViewModel.onComplete → authViewModel.appState = .main`
- `FirestoreService` uses `Auth.currentUserID` (internal private enum) to avoid importing FirebaseAuth everywhere
- `CoreDataOfflineQueue` uses JSON blob storage (not mapped entities) — schema-stable
- HealthKit status re-checked on every `scenePhase == .active` in `HomeView`
- `ZonePreviewView` accesses `authViewModel.authService.currentUserID` to pass to `saveProfile(userID:)`
