# Business Logic Model — Unit 3: iPhone Workout Engine

---

## 1. Pre-Start Flow

```
User taps "Start Workout" on HomeView
  │
  └── WorkoutSessionManager.selectProgram(profile.preferredWorkout)
        → state = .preStart(program)
        → navigate to WorkoutPreStartView

WorkoutPreStartView shows:
  - Selected program (defaulted from preferredWorkout)
  - Picker to change program (Continuous / HIIT / Fartlek)
  - "Begin" button

User taps "Begin"
  └── WorkoutSessionManager.start(userID:, zones:)
```

---

## 2. Workout Start Flow

```
WorkoutSessionManager.start(userID:, zones:)
  │
  ├── Create WorkoutPhaseSequencer(program: selectedProgram)
  ├── Create CoachingEngine(zones: zones)
  ├── hrStream = []
  ├── elapsedSeconds = 0
  ├── state = .active
  │
  ├── WatchBridge.send(.workoutStarted)  → Watch activates HR display
  │
  └── Start 5-second timer loop:
        every 5 seconds:
          1. sequencer.advance(by: 5) → check for phase transitions
          2. elapsedSeconds += 5
          3. Append HRRecord to hrStream (if HR available)
          4. CoachingEngine.tick(hr:, phase:, elapsedInPhase:)
          5. If CoachingMessage returned:
               → VoiceFeedbackService.speak(message)
               → WatchBridge.send(.haptic(message.haptic))
               → WorkoutViewModel.coachingMessage = message.text
          6. Check if sequencer.isComplete → trigger mainWorkoutComplete
```

---

## 3. Three-Layer Coaching Algorithm

Called every 5 seconds via `CoachingEngine.tick()`.

### Inputs
- `hr: Int` — raw HR reading from Watch
- `phase: WorkoutPhase` — current phase (has targetZone, type, hasGracePeriod)
- `elapsedInPhase: TimeInterval` — seconds elapsed in current phase

### Step 1: HR Smoothing
```
hrBuffer.append(hr)
IF hrBuffer.count > 2: hrBuffer.removeFirst()
hrSmooth = hrBuffer.reduce(0, +) / hrBuffer.count
```

### Step 2: Layer 1 — Safety Check (always evaluated first)
```
IF hr == 0:
  → CoachingMessage(text: "No heart rate signal. Please check your Watch.",
                    layer: .safety, haptic: nil)
  → RETURN (skip layers 2 and 3)

IF hr > zones.zone5.max:   // hr > HRmax
  → WorkoutSessionManager.emergencyStop()
  → CoachingMessage(text: "Heart rate too high! Please stop immediately.",
                    layer: .safety, haptic: .emergencyRepeated)
  → RETURN
```

### Step 3: Layer 2 — Zone Coaching
```
PRECONDITIONS (all must pass):
  ├── phase.targetZone != nil          // skip recovery phases
  ├── NOT sequencer.isGracePeriodActive // first 10s of HIIT/Fartlek phase
  └── lastLayer2MessageAt == nil
      OR Date().timeIntervalSince(lastLayer2MessageAt!) > 20  // anti-spam

IF hrSmooth < targetZone.min:
  → message = "Speed up"
  → haptic = .short
  → reset consecutiveInZoneSeconds = 0

ELSE IF hrSmooth > targetZone.max:
  → message = "Slow down"
  → haptic = .long
  → reset consecutiveInZoneSeconds = 0

ELSE (in zone):
  → no Layer 2 message
  → consecutiveInZoneSeconds += 5   (for Layer 3)

IF Layer 2 message generated:
  → lastLayer2MessageAt = Date()
  → RETURN CoachingMessage (skip Layer 3)
```

### Step 4: Layer 3 — Positive Feedback
```
ONLY evaluated if Layer 2 did NOT fire and phase has targetZone

IF consecutiveInZoneSeconds >= 30:
  AND (lastLayer3MessageAt == nil
       OR Date().timeIntervalSince(lastLayer3MessageAt!) > 30):
  → CoachingMessage(text: "Great work! Keep it up.",
                    layer: .positiveFeedback, haptic: .doubleTap)
  → lastLayer3MessageAt = Date()
  → consecutiveInZoneSeconds = 0    // reset after firing
  → RETURN message

ELSE:
  → RETURN nil  (no coaching this tick)
```

### Layer Priority Summary
```
Safety (Layer 1) → ALWAYS checked first; if triggered, stops evaluation
Zone Coaching (Layer 2) → checked if safety passes + preconditions met
Positive Feedback (Layer 3) → checked only if Layer 2 did not fire
```

---

## 4. Phase Transition Handling

```
sequencer.advance(by: 5) returns SequencerEvent

.phaseTransition(newPhase):
  ├── WorkoutViewModel.phase = newPhase
  ├── WatchBridge.send(.showCoachingOverlay("Zone \(newPhase.targetZone ?? 0)"))
  ├── IF newPhase.type == .recovery:
  │     VoiceFeedbackService.speak("Recovery time. Walk it out.")
  └── CoachingEngine.state.consecutiveInZoneSeconds = 0
      CoachingEngine.state.lastLayer2MessageAt = nil  (fresh anti-spam per phase)

.mainWorkoutComplete:
  └── state = .complete(assembleSession())
      VoiceFeedbackService.speak("Workout complete! Great job.")
      WatchBridge.send(.workoutStopped)
```

---

## 5. Pause / Resume Flow

### Pause
```
WorkoutSessionManager.pause()
  ├── state = .paused
  ├── timer loop suspended
  ├── WatchBridge.send(.workoutStopped)   // Watch pauses HKWorkoutSession
  └── VoiceFeedbackService stops speaking
```

### Resume
```
WorkoutSessionManager.resume()
  ├── state = .active
  ├── timer loop resumes
  ├── WatchBridge.send(.workoutStarted)   // Watch resumes HKWorkoutSession
  └── Grace period NOT reset on resume (phase continues where it left off)
```

---

## 6. Emergency Stop Flow

```
CoachingEngine detects hr > HRmax
  │
  ├── WorkoutSessionManager.emergencyStop()
  │     ├── state = .emergencyStopped
  │     └── timer loop suspended
  │
  ├── VoiceFeedbackService.speak("Heart rate too high! Please stop immediately.")
  ├── WatchBridge.send(.emergencyStop)   → Watch shows full-screen alert
  └── WorkoutViewModel shows full-screen emergency overlay

User acknowledges
  └── WorkoutSessionManager.end()  → state = .complete(assembleSession())
```

---

## 7. Session Assembly

Called when workout completes (normally or via emergency stop).

```swift
func assembleSession() -> Session {
    let avgHR = hrStream.isEmpty ? 0 : hrStream.map(\.hr).reduce(0, +) / hrStream.count
    let maxHR = hrStream.map(\.hr).max() ?? 0

    var timeInZones: [Int: Int] = [:]
    for record in hrStream where record.currentZone >= 1 && record.currentZone <= 5 {
        timeInZones[record.currentZone, default: 0] += 5
    }

    return Session(
        date: workoutStartDate,
        programType: selectedProgram.workoutType,
        durationSec: Int(elapsedSeconds),
        avgHR: avgHR,
        timeInZones: timeInZones,
        hrStream: hrStream
    )
}
```

`maxHR` is computed in `WorkoutSummaryViewModel` from `session.hrStream` at display time (not stored in `Session` — derives from existing data).

---

## 8. Session Save Flow

```
WorkoutSummaryView appears with completed Session
  │
  └── User taps "Done"
        │
        └── WorkoutSummaryViewModel.save(userID:)
              ├── isSaving = true
              ├── firebaseService.saveSession(session, userID:)
              │     ├── online  → save to Firestore
              │     └── offline → CoreDataOfflineQueue.enqueue(session)
              ├── isSaving = false
              └── navigate to Home (via WorkoutSessionManager.state = .idle)
```

---

## 9. History Loading

```
HistoryView appears
  └── HistoryViewModel.loadSessions(userID:)
        ├── firebaseService.loadSessions(userID:, limit: 50)
        └── sessions = sorted by date descending
```

User taps a session row → `selectedSession` set → `SessionDetailView` pushed.
