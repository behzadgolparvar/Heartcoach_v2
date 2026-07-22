# Frontend Components — Unit 4: Apple Watch App

## Component Tree

```
WatchApp (@main)
  └── WatchRootView
      ├── IdleWatchView          (isWorkoutActive == false)
      └── WorkoutWatchView       (isWorkoutActive == true)
```

---

## WatchRootView

**File**: `HeartCoachWatch/Views/WatchRootView.swift`
**Type**: SwiftUI `View`
**Responsibility**: Switches between idle and active workout screens based on `viewModel.isWorkoutActive`.

```
if isWorkoutActive {
    WorkoutWatchView()
} else {
    IdleWatchView()
}
```

Transition: `.animation(.easeInOut)` on the `isWorkoutActive` toggle.

---

## IdleWatchView

**File**: `HeartCoachWatch/Views/IdleWatchView.swift`
**Type**: SwiftUI `View`
**Shown when**: No workout is active.

**Layout** (vertical stack, centered):
```
        ❤️
   HeartCoach
   
  Start workout
    on iPhone
```

- Heart icon: `Image(systemName: "heart.fill")` in red, 36pt
- App name: `.title3.bold()` white
- Instruction: `.footnote` secondary color, centered

No interactive elements — the Watch is purely a display in idle state.

---

## WorkoutWatchView

**File**: `HeartCoachWatch/Views/WorkoutWatchView.swift`
**Type**: SwiftUI `View`
**Shown when**: `isWorkoutActive == true`

**Layout** (vertical stack):

```
┌─────────────────────┐
│   Exercise          │  ← phaseName — .caption, secondary
│                     │
│   ❤️ 152            │  ← HR — .system(size:48, weight:.bold), zone-colored
│   Zone 3            │  ← zone label — .subheadline, zone-colored
│                     │
│ Speed up a little   │  ← lastMessage — .footnote, white.opacity(0.8)
│                     │    nil → empty space (no layout shift)
└─────────────────────┘
```

**Zone color mapping**:
| Zone | Color |
|---|---|
| 0 (no signal) | `.gray` |
| 1 | `.blue` |
| 2 | `.green` |
| 3 | `.yellow` |
| 4 | `.orange` |
| 5 | `.red` |

**HR animation**: `.animation(.easeInOut(duration: 0.3), value: currentHR)` — smooth number transition on each new reading.

**Coaching message**: Shows only the most recent message. No history. When a new message arrives it replaces the previous one with `.transition(.opacity)`.

**No user interaction**: WorkoutWatchView has no buttons. All workout control (pause, end, emergency stop) is done on the iPhone. This is intentional — the Watch is display-only during a workout.

---

## Accessibility

| Element | Accessibility |
|---|---|
| HR number | `accessibilityLabel("Heart rate \(hr) beats per minute")` |
| Zone label | `accessibilityLabel("Zone \(zone)")` |
| Phase name | Default label (text content) |
| Coaching message | `accessibilityLabel(lastMessage ?? "No coaching message")` |

---

## Watch Target Details

**Target name**: `HeartCoachWatch`
**Platform**: watchOS 10.0+
**Bundle ID**: `com.behzad.heartcoach.watchkitapp`
**Extension**: Not needed — modern watchOS uses a single app target (no WatchKit extension)

**Entitlements**:
- `com.apple.developer.healthkit` — for HKWorkoutSession
- `com.apple.developer.healthkit.background-delivery` — keep HR sensor active when screen off

**Info.plist additions**:
- `NSHealthShareUsageDescription` — "HeartCoach reads your heart rate during workouts."
- `WKWatchOnly` — `false` (requires iPhone companion app)
- `WKCompanionAppBundleIdentifier` — `com.behzad.heartcoach`
