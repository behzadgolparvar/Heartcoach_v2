# Frontend Components — Unit 2: iPhone Foundation

All views use SwiftUI. Dark mode is the primary UI style. `@Observable` ViewModels are injected via the SwiftUI environment or initialiser.

---

## Navigation Architecture

```
HeartCoachApp (@main)
  └── RootView
        ├── LoadingView            ← appState == .loading
        ├── SignInView             ← appState == .signedOut
        ├── OnboardingContainerView ← appState == .onboarding
        └── MainTabView            ← appState == .main
              ├── Tab 0: HomeView
              ├── Tab 1: HistoryPlaceholderView   (Unit 3)
              └── Tab 2: SettingsView
                          └── ZoneDetailView (pushed)
```

---

## RootView

**Purpose**: Switches the displayed root screen based on `AuthViewModel.appState`.

**ViewModel**: `AuthViewModel`

**Behaviour**:
- Calls `authViewModel.checkAuthState()` on appear
- Animates transitions between states with `.transition(.opacity)`

---

## LoadingView

**Purpose**: Shown briefly while Firebase checks auth state on launch.

**Contents**:
- App logo / wordmark centred
- `ProgressView` spinner below logo
- No user interaction

---

## SignInView

**Purpose**: Entry point for unauthenticated users.

**ViewModel**: `AuthViewModel`

**Layout**:
```
┌──────────────────────────────┐
│                              │
│         HeartCoach           │  ← app name + tagline
│   "Train smarter. Not       │
│    harder."                  │
│                              │
│   [Sign in with Apple]       │  ← `SignInWithAppleButton`
│                              │
│   (error message if any)     │  ← authViewModel.errorMessage
│                              │
└──────────────────────────────┘
```

**Accessibility**: `accessibilityIdentifier("signin-apple-button")`

---

## OnboardingContainerView

**Purpose**: Hosts the 4-step wizard, manages back/forward navigation.

**ViewModel**: `OnboardingViewModel`

**Layout**: `NavigationStack` driven by `currentStep`. Each step is a distinct view pushed onto the stack. Progress indicator (step 1/4, 2/4, etc.) shown in the navigation bar.

---

## PhysiologicalDataView (Onboarding Step 1)

**Purpose**: Collect age and resting HR. Request HealthKit authorization.

**ViewModel**: `OnboardingViewModel`

**Layout**:
```
┌──────────────────────────────┐
│ ← (back disabled on step 1) │
│ Step 1 of 4       [●○○○]    │
│                              │
│ Your Body Data               │
│                              │
│ Age                          │
│ [_______________] years      │
│                              │
│ Resting Heart Rate           │
│ [_______________] bpm        │
│ ⓘ "Find this in Apple       │
│    Health → Summary →        │
│    Heart → Resting HR"       │
│                              │
│ ⚠️ (RHRWarning if present)  │
│ ❌ (fieldError if present)   │
│                              │
│ [Allow Heart Rate Access]    │  ← calls healthKitService
│  ✓ Granted / ✗ Denied       │
│                              │
│          [ Next → ]          │
└──────────────────────────────┘
```

**Validation on "Next"**: age + RHR validated; `ZoneCalculator.calculate()` called. Errors shown inline.

**Accessibility**:
- Age field: `accessibilityIdentifier("onboarding-age-field")`
- RHR field: `accessibilityIdentifier("onboarding-rhr-field")`
- Next button: `accessibilityIdentifier("onboarding-step1-next")`

---

## OptionalDetailsView (Onboarding Step 2)

**Purpose**: Collect optional sex and weight. Fully skippable.

**ViewModel**: `OnboardingViewModel`

**Layout**:
```
┌──────────────────────────────┐
│ ←                [●●○○]     │
│                              │
│ Optional Details             │
│ (You can skip this)          │
│                              │
│ Biological Sex               │
│ ○ Male  ○ Female  ○ Other   │
│                              │
│ Weight                       │
│ [_______________] kg         │
│                              │
│ [ Skip ]      [ Next → ]    │
└──────────────────────────────┘
```

**Accessibility**:
- Skip button: `accessibilityIdentifier("onboarding-step2-skip")`
- Next button: `accessibilityIdentifier("onboarding-step2-next")`

---

## PreferencesView (Onboarding Step 3)

**Purpose**: Collect training goal and preferred workout type.

**ViewModel**: `OnboardingViewModel`

**Layout**:
```
┌──────────────────────────────┐
│ ←                [●●●○]     │
│                              │
│ Your Training Goals          │
│                              │
│ Primary Goal                 │
│ ○ Fat Burn                   │
│ ○ Endurance                  │
│                              │
│ Preferred Workout            │
│ ○ Continuous                 │
│ ○ HIIT                       │
│ ○ Fartlek                    │
│                              │
│          [ Next → ]          │
└──────────────────────────────┘
```

**Accessibility**:
- Next button: `accessibilityIdentifier("onboarding-step3-next")`

---

## ZonePreviewView (Onboarding Step 4)

**Purpose**: Show computed HR zones. "Start Training" triggers profile save and navigates to main app.

**ViewModel**: `OnboardingViewModel`

**Layout**:
```
┌──────────────────────────────┐
│                   [●●●●]    │
│                              │
│ Your Personalised Zones      │
│                              │
│ ┌────────────────────────┐   │
│ │ Zone 1  Recovery        │   │
│ │         125 – 138 bpm  │   │
│ │ Zone 2  Fat Burn        │   │
│ │         138 – 151 bpm  │   │
│ │ Zone 3  Aerobic         │   │
│ │         151 – 164 bpm  │   │
│ │ Zone 4  Threshold       │   │
│ │         164 – 177 bpm  │   │
│ │ Zone 5  Max Effort      │   │
│ │         177 – 190 bpm  │   │
│ └────────────────────────┘   │
│                              │
│   [  Start Training  ]       │  ← saves profile, goes to .main
│   (spinner while saving)     │
└──────────────────────────────┘
```

**Accessibility**:
- Start Training button: `accessibilityIdentifier("onboarding-start-training")`

---

## MainTabView

**Purpose**: Root tab bar for authenticated users with a profile.

**Tabs**:

| Index | Label | Icon | View |
|---|---|---|---|
| 0 | Home | `house.fill` | `HomeView` |
| 1 | History | `list.bullet` | `HistoryPlaceholderView` |
| 2 | Settings | `gearshape.fill` | `SettingsView` |

---

## HomeView

**Purpose**: Primary screen. Shows zone card (no sessions) or last session summary. Always has Start Workout button.

**ViewModel**: `HomeViewModel`

**Layout — Empty state (no sessions)**:
```
┌──────────────────────────────┐
│ HeartCoach            ⋮      │
│                              │
│ Good morning! 👋             │
│                              │
│ ┌────────────────────────┐   │
│ │ Your HR Zones           │   │
│ │ Zone 1  125–138 bpm    │   │
│ │ Zone 2  138–151 bpm    │   │
│ │ ...                    │   │
│ │ [View all zones →]     │   │
│ └────────────────────────┘   │
│                              │
│    [ Start Workout ]         │
└──────────────────────────────┘
```

**Layout — With sessions**:
```
┌──────────────────────────────┐
│ HeartCoach            ⋮      │
│                              │
│ Last Session                 │
│ ┌────────────────────────┐   │
│ │ Today · 35 min         │   │
│ │ Avg HR: 152 bpm        │   │
│ │ ██░░░  Zone 3: 18 min  │   │
│ └────────────────────────┘   │
│                              │
│    [ Start Workout ]         │
└──────────────────────────────┘
```

**Accessibility**:
- Start Workout button: `accessibilityIdentifier("home-start-workout")`

---

## HistoryPlaceholderView

**Purpose**: Placeholder for Unit 3. Shown on History tab in Unit 2.

**Contents**: "Workout history coming soon" message with icon.

---

## SettingsView

**Purpose**: Edit profile and preferences. Explicit Save button.

**ViewModel**: `SettingsViewModel`

**Layout**:
```
┌──────────────────────────────┐
│ Settings                     │
│                              │
│ Profile                      │
│ Age             [  32  ]     │
│ Resting HR      [  62  ] bpm │
│ Sex             Male ▼       │
│ Weight          [ 75.0 ] kg  │
│                              │
│ Training                     │
│ Goal            Fat Burn ▼   │
│ Workout         HIIT ▼       │
│                              │
│ ── Zone Preview ──           │
│ Zone 1  125–138 bpm          │  ← live, local only
│ Zone 2  138–151 bpm          │
│ ...                          │
│                              │
│ ❌ (fieldError if present)   │
│                              │
│          [ Save ]            │
│                              │
│ ─────────────────────────── │
│ [ Sign Out ]                 │
└──────────────────────────────┘
```

**Accessibility**:
- Age field: `accessibilityIdentifier("settings-age-field")`
- RHR field: `accessibilityIdentifier("settings-rhr-field")`
- Save button: `accessibilityIdentifier("settings-save")`
- Sign Out button: `accessibilityIdentifier("settings-sign-out")`

---

## ZoneDetailView

**Purpose**: Full-screen zone breakdown. Pushed from Home zone card "View all zones" link or Settings.

**Contents**: All 5 zones with name, bpm range, and a brief description of each zone's training purpose.

**Accessibility**: `accessibilityIdentifier("zone-detail-view")`
