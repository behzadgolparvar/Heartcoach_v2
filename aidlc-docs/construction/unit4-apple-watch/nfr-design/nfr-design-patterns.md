# NFR Design Patterns — Unit 4: Apple Watch App

## Pattern 1: WCSession Message Routing

**Decision**: All incoming WCSession messages arrive via `session(_:didReceiveMessage:)` on a background queue. A single routing switch decodes the message key and dispatches the appropriate action to `@MainActor` for any ViewModel update.

```swift
func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    if let command = message["command"] as? String {
        switch command {
        case "workoutStarted": Task { @MainActor in startWorkout() }
        case "workoutStopped": Task { @MainActor in stopWorkout() }
        default: break
        }
    } else if let rawHaptic = message["haptic"] as? String,
              let pattern = HapticPattern(rawValue: rawHaptic) {
        hapticService.play(pattern)              // fire immediately on background queue — no need for MainActor
    } else if let zone = message["zone"] as? Int {
        Task { @MainActor in
            viewModel.currentZone = zone
            viewModel.phaseName = (message["phase"] as? String).flatMap { PhaseType(rawValue: $0) }?.displayName ?? ""
            viewModel.lastMessage = message["message"] as? String
        }
    }
}
```

Haptic execution does **not** need `@MainActor` — `WKInterfaceDevice.current().play()` is thread-safe and fires faster without the main thread hop.

---

## Pattern 2: HKWorkoutSession Lifecycle

**Decision**: `HRService` creates and manages the `HKWorkoutSession`. Lifetime: created on `workoutStarted` command, ended on `workoutStopped` or emergency stop.

```swift
func start() {
    let config = HKWorkoutConfiguration()
    config.activityType = .running
    config.locationType = .outdoor

    do {
        session = try HKWorkoutSession(healthStore: store, configuration: config)
        builder = session!.associatedWorkoutBuilder()
        builder!.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
        session!.delegate = self
        builder!.delegate = self
        session!.startActivity(with: Date())
        builder!.beginCollection(withStart: Date()) { _, _ in }
    } catch {
        // Session creation failed — WatchSessionManager will not call sendHR
    }
}

func stop() {
    session?.end()
    builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
        self?.builder?.finishWorkout { _, _ in }   // saves to Apple Health (Q1 — A)
    }
    session = nil
    builder = nil
}
```

---

## Pattern 3: Live HR Extraction

**Decision**: `HKLiveWorkoutBuilderDelegate.workoutBuilder(_:didCollectDataOf:)` fires when new samples arrive. Extract the most recent HR quantity, convert to bpm, wrap in `HRReading`, forward to `WatchSessionManager`.

```swift
func workoutBuilder(_ builder: HKLiveWorkoutBuilder,
                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
    guard collectedTypes.contains(HKQuantityType(.heartRate)) else { return }
    guard let quantity = builder
        .statistics(for: HKQuantityType(.heartRate))?
        .mostRecentQuantity() else { return }

    let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    onHRReading?(HRReading(value: Int(bpm)))
}
```

No HR values are logged. The bpm value is immediately wrapped in `HRReading` and forwarded — never stored in a variable that could appear in a crash report.

---

## Pattern 4: HKWorkoutSession Recovery (Q1 — A)

**Decision**: On app launch, call `recoverActiveWorkoutSession`. If an active session is found (app was suspended mid-workout), reconnect `HRService` to it and resume HR streaming.

```swift
// Called in WatchApp.init() or WatchSessionManager.activate()
func recoverIfNeeded() {
    store.recoverActiveWorkoutSession { [weak self] session, error in
        guard let session, error == nil else { return }
        Task { @MainActor in
            self?.hrService.reconnect(to: session)
            self?.viewModel.isWorkoutActive = true
        }
    }
}
```

`HRService.reconnect(to:)` re-assigns the delegate and re-attaches `HKLiveWorkoutBuilder` to the recovered session. HR streaming resumes on the next sensor sample.

---

## Pattern 5: Haptic Execution

**Decision**: Decode `HapticPattern` raw value from WCSession message → map to `WKHapticType` → fire synchronously. No queue, no delay.

```swift
func play(_ pattern: HapticPattern) {
    let type: WKHapticType
    switch pattern {
    case .short:             type = .notification
    case .long:              type = .directionUp
    case .doubleTap:         type = .success
    case .emergencyRepeated: type = .retry
    }
    WKInterfaceDevice.current().play(type)
}
```

`.retry` (emergency) bypasses the Watch's silent/theater mode — the user always feels the emergency tap.

---

## Pattern 6: HealthKit Save on Session End (Q1 NFR — A)

**Decision**: `builder.finishWorkout(completion:)` is called (not `discardWorkout()`). The workout is saved to Apple Health with HR samples and duration, contributing to Activity rings.

The completion handler is fire-and-forget — no error handling needed beyond silent failure, since Firebase (via iPhone) holds the authoritative session record.

---

## Pattern 7: Thread Safety

All Watch callbacks arrive on background queues. Rule: ViewModel properties are only mutated inside `Task { @MainActor in … }`. Haptic playback is the only exception — it is safe and faster on the background queue.

| Source | Queue | ViewModel update |
|---|---|---|
| `WCSession` delegate callbacks | Background | `Task { @MainActor in … }` |
| `HKLiveWorkoutBuilder` delegate | Background | `Task { @MainActor in … }` |
| `HKWorkoutSession` delegate | Background | `Task { @MainActor in … }` |
| Haptic playback | Background (OK) | No ViewModel update |

---

## Security Compliance (Unit 4)

| Rule | Applied in Pattern |
|---|---|
| SECURITY-03 (no health data in logs) | Pattern 3: bpm never stored in a loggable variable; immediately wrapped in `HRReading` |
| SECURITY-11 (health data classification) | HR only sent to iPhone over local Bluetooth WCSession |
| SECURITY-15 (no raw errors to user) | WCSession and HealthKit errors silently dropped; no error shown on Watch UI |
