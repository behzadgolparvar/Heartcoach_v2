# Frontend Components — Unit 3: iPhone Workout Engine

---

## Navigation Flow

```
HomeView
  └── [Start Workout] → WorkoutPreStartView
                              └── [Begin] → WorkoutView
                                               ├── [Pause] → (same view, paused state)
                                               ├── [End]   → WorkoutSummaryView
                                               │                  └── [Done] → HomeView
                                               └── [Emergency] → EmergencyStopOverlay
                                                                     └── [OK] → WorkoutSummaryView

MainTabView → History tab → HistoryView
                                └── session row → SessionDetailView
```

---

## WorkoutPreStartView

**Purpose**: Confirms workout selection before starting. Defaults to user's preferred workout.

**ViewModel**: `WorkoutSelectionViewModel` (lightweight — just holds selected program)

**Layout**:
```
┌──────────────────────────────┐
│  Start Workout               │
│                              │
│  ○ Continuous                │
│    Steady progressive · 35m  │
│                              │
│  ● HIIT          ← selected  │
│    15 intervals · 35m        │
│                              │
│  ○ Fartlek                   │
│    Varied pace · 35m         │
│                              │
│  [ Begin ]                   │
└──────────────────────────────┘
```

**Behaviour**: Tapping "Begin" calls `WorkoutSessionManager.start(userID:, zones:)` and navigates to `WorkoutView`.

---

## WorkoutView

**Purpose**: Main live coaching screen. Shown throughout the entire workout (active + paused states).

**ViewModel**: `WorkoutViewModel`

**Layout — Active, exercise phase**:
```
┌──────────────────────────────┐
│  HIIT · Cycle 4 of 15   ⏸   │  ← phase label + pause button
│                              │
│         ┌─────────┐          │
│         │  Zone 3 │          │  ← zone ring (coloured)
│         │ 148 bpm │          │  ← smoothed HR
│         │ Target 3│          │
│         └─────────┘          │
│                              │
│  "Speed up"                  │  ← coaching cue (last message)
│                              │
│  0:38 remaining in phase     │  ← phase countdown
│  Total: 14:22 elapsed        │  ← total elapsed time
│                              │
│  [ End Workout ]             │
└──────────────────────────────┘
```

**Layout — Recovery phase** (Q2 — A):
```
┌──────────────────────────────┐
│  HIIT · Recovery        ⏸   │
│                              │
│         ┌─────────┐          │
│         │Recovery │          │  ← ring is grey (neutral)
│         │ 122 bpm │          │  ← current HR still shown
│         │No target│          │
│         └─────────┘          │
│                              │
│  "Walk it out / don't stop"  │  ← fixed phase instruction
│                              │
│  0:45 remaining in phase     │
│  Total: 15:15 elapsed        │
│                              │
│  [ End Workout ]             │
└──────────────────────────────┘
```

**Layout — Paused state**:
```
┌──────────────────────────────┐
│  PAUSED                 ▶    │  ← resume button replaces pause
│                              │
│         ┌─────────┐          │
│         │  PAUSED │          │  ← ring shows "PAUSED" label
│         │ 138 bpm │          │
│         └─────────┘          │
│                              │
│  Tap ▶ to resume             │
│                              │
│  [ End Workout ]             │
└──────────────────────────────┘
```

**Accessibility**:
- Pause button: `accessibilityIdentifier("workout-pause")`
- Resume button: `accessibilityIdentifier("workout-resume")`
- End button: `accessibilityIdentifier("workout-end")`

---

## EmergencyStopOverlay

**Purpose**: Full-screen alert when HR exceeds HRmax. Covers `WorkoutView`.

**Layout**:
```
┌──────────────────────────────┐
│  🛑 STOP IMMEDIATELY         │
│                              │
│  Your heart rate is too      │
│  high. Please stop and rest. │
│                              │
│  HR: 198 bpm                 │
│  Max: 190 bpm                │
│                              │
│  [ I'm OK — End Workout ]    │
└──────────────────────────────┘
```

**Behaviour**: Cannot be dismissed without tapping the button. Tapping ends the workout and goes to `WorkoutSummaryView`.

**Accessibility**: `accessibilityIdentifier("emergency-stop-overlay")`

---

## WorkoutSummaryView

**Purpose**: Detailed post-workout summary (Q5 — B). Shown after every completed workout.

**ViewModel**: `WorkoutSummaryViewModel`

**Layout**:
```
┌──────────────────────────────┐
│  Workout Complete! 🎉        │
│                              │
│  HIIT · 35:18                │  ← workout type + duration
│                              │
│  Avg HR    Max HR            │
│  152 bpm   178 bpm           │
│                              │
│  Time in Zones               │
│  ┌──────────────────────┐    │
│  │ Z1 Recovery   1 min  │    │
│  │ Z2 Fat Burn   4 min  │    │
│  │ Z3 Aerobic    8 min  │    │
│  │ Z4 Threshold  15 min │    │
│  │ Z5 Max Effort 7 min  │    │
│  └──────────────────────┘    │
│                              │
│  ████████░░ Zone bar         │
│                              │
│  (Saving…) or               │
│  [ Done ]                   │
│                              │
│  (error message if save fails)│
└──────────────────────────────┘
```

**Behaviour**:
- "Done" calls `WorkoutSummaryViewModel.save(userID:)` then navigates to Home
- While saving: `ProgressView` replaces "Done" button
- If save fails: error banner shown with "Retry" option

**Accessibility**: `accessibilityIdentifier("summary-done-button")`

---

## HistoryView

**Purpose**: Scrollable list of all past sessions. Replaces `HistoryPlaceholderView` from Unit 2.

**ViewModel**: `HistoryViewModel`

**Layout**:
```
┌──────────────────────────────┐
│  History                     │
│                              │
│  ┌────────────────────────┐  │
│  │ HIIT · Today           │  │  ← session row
│  │ 35:18 · Avg 152 bpm    │  │
│  │ ████░░ zone bar         │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ Continuous · Yesterday  │  │
│  │ 35:01 · Avg 144 bpm    │  │
│  └────────────────────────┘  │
│  ...                         │
└──────────────────────────────┘
```

Tapping a row pushes `SessionDetailView`.

**Empty state** (no sessions yet): "No workouts yet. Complete your first session to see it here."

---

## SessionDetailView

**Purpose**: Full detail for a single past session. Same layout as `WorkoutSummaryView` but read-only (no "Done" button, no save logic).

**Contents**: Workout type, date, duration, avgHR, maxHR, time-in-zones breakdown, zone bar.

---

## Zone Ring Component

Reusable circular indicator used in `WorkoutView`.

| State | Colour | Label |
|---|---|---|
| Zone 1 | Blue | "Zone 1" |
| Zone 2 | Green | "Zone 2" |
| Zone 3 | Yellow | "Zone 3" |
| Zone 4 | Orange | "Zone 4" |
| Zone 5 | Red | "Zone 5" |
| Recovery | Grey | "Recovery" |
| Paused | Grey | "PAUSED" |
| No signal | Red pulsing | "No Signal" |

The ring border colour changes to match the current zone. The target zone is shown as a subtle arc segment on the ring.
