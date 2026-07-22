# Business Logic Model — Unit 4: Apple Watch App

## Flow 1: App Startup

**Trigger**: User opens Watch app (or app is launched by WCSession activation).

```
WatchApp.init()
  → WatchSessionManager.activate()
      → WCSession.default.delegate = self
      → WCSession.default.activate()
  → WorkoutWatchViewModel initialised (isWorkoutActive = false)
  → IdleWatchView shown ("Start workout on iPhone")
```

HealthKit authorization is NOT requested by the Watch app independently. The iPhone app requests HealthKit authorization (Units 2). The Watch inherits the same authorization scope — if the user approved on the iPhone, the Watch can read HR without a separate prompt.

---

## Flow 2: Workout Start (iPhone → Watch)

**Trigger**: User taps "Start Workout" on iPhone; `WorkoutSessionManager.start()` runs; `WatchBridge` sends `["command": "workoutStarted"]` to Watch.

```
WCSession.default.sendMessage(["command": "workoutStarted"], ...)  ← iPhone

WatchSessionManager.session(_:didReceiveMessage:)                   ← Watch receives
  → command == "workoutStarted"
  → HRService.start()
      → HKWorkoutConfiguration(activityType: .running, locationType: .outdoor)
      → HKHealthStore().startWatchApp(toHandle: configuration, ...) [if needed]
      → session.startActivity(with: Date())
      → builder.beginCollection(withStart: Date())
  → viewModel.isWorkoutActive = true                               ← triggers UI switch
  → WorkoutWatchView shown
```

---

## Flow 3: Live HR Streaming (Watch → iPhone)

**Trigger**: `HKLiveWorkoutBuilder` fires delegate callback when new HR sample arrives (~every 5 seconds).

```
HKLiveWorkoutBuilderDelegate.workoutBuilder(_:didCollectDataOf:)
  → types contains HKQuantityTypeIdentifier.heartRate
  → builder.statistics(for: .heartRate)?.mostRecentQuantity()
  → bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
  → reading = HRReading(value: Int(bpm))
  → WatchSessionManager.sendHR(reading)
      → guard WCSession.default.isReachable else { return }        ← fire-and-forget
      → WCSession.default.sendMessage(["hr": reading.value], replyHandler: nil, errorHandler: { _ in })
  → viewModel.currentHR = Int(bpm)                                 ← local display update
```

**Fire-and-forget**: If the iPhone is not reachable (Bluetooth gap), the HR reading is silently dropped. The iPhone's staleness tracker handles gaps up to 14 seconds without triggering a warning.

---

## Flow 4: Coaching State Update (iPhone → Watch)

**Trigger**: iPhone `WorkoutSessionManager.processTick()` publishes updated `CoachingState`; `WatchBridge` sends it to Watch.

```
WCSession.default.sendMessage([
    "zone": coachingState.currentZone,
    "phase": coachingState.phase.rawValue,
    "message": coachingState.coachingMessage ?? ""
], ...)                                                             ← iPhone sends

WatchSessionManager.session(_:didReceiveMessage:)                   ← Watch receives
  → viewModel.currentZone = message["zone"] as? Int ?? 0
  → viewModel.phaseName = PhaseType(rawValue: message["phase"])?.displayName ?? ""
  → viewModel.lastMessage = message["message"] as? String
```

---

## Flow 5: Haptic Execution (iPhone → Watch)

**Trigger**: `CoachingEngine.tick()` returns a `CoachingMessage` with a `hapticPattern`; `WatchBridge` sends it.

```
WCSession.default.sendMessage(["haptic": pattern.rawValue], ...)    ← iPhone sends

WatchSessionManager.session(_:didReceiveMessage:)                   ← Watch receives
  → rawValue = message["haptic"] as? String
  → pattern = HapticPattern(rawValue: rawValue)
  → HapticService.play(pattern)
      → WKInterfaceDevice.current().play(mappedType)
```

**Timing**: The iPhone sends the haptic message at the same moment it speaks the coaching cue. WCSession typically delivers within 50–200ms — the user feels the tap and hears the voice simultaneously.

---

## Flow 6: Workout End (iPhone → Watch)

**Trigger**: User taps "End Workout" on iPhone or workout completes naturally.

```
WCSession.default.sendMessage(["command": "workoutStopped"], ...)   ← iPhone sends

WatchSessionManager.session(_:didReceiveMessage:)                   ← Watch receives
  → command == "workoutStopped"
  → HRService.stop()
      → session.end()
      → builder.endCollection(withEnd: Date(), completion: { _, _ in })
      → session = nil; builder = nil
  → viewModel.isWorkoutActive = false
  → viewModel.currentHR = 0
  → viewModel.lastMessage = nil
  → IdleWatchView shown
```

---

## Flow 7: WCSession Reachability Loss During Workout

**Trigger**: Bluetooth connection drops between iPhone and Watch during an active workout.

```
WatchSessionManager.sessionReachabilityDidChange(_:)
  → WCSession.default.isReachable == false
  → HRService continues running (HR sensor stays active)
  → sendHR() guard fails silently — readings dropped until reconnect
  → iPhone staleness tracker triggers "no signal" Layer 1 after 15s

On reconnect:
  → WCSession.default.isReachable == true
  → HR readings resume flowing to iPhone
  → iPhone staleness clears on next valid reading
  → Coaching resumes normally
```

---

## Business Rules

| Rule | Detail |
|---|---|
| BR-W1 | Watch starts HKWorkoutSession only on receipt of `workoutStarted` command — never independently |
| BR-W2 | HR readings are sent fire-and-forget — no retry, no acknowledgement |
| BR-W3 | Haptic execution is immediate — no queue, no retry |
| BR-W4 | Watch does not persist any session data — no HealthKit write, no local storage |
| BR-W5 | Watch HealthKit access is read-only (HR quantity type, read permission only) |
| BR-W6 | `emergencyRepeated` haptic fires regardless of Watch "silent mode" setting (using `.retry` type, which bypasses silent) |
