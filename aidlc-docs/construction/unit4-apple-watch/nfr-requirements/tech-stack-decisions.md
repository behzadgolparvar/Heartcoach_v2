# Tech Stack Decisions — Unit 4: Apple Watch App

## Language & Platform

| Decision | Choice | Rationale |
|---|---|---|
| Swift version | Swift 5.9 | Consistent with Units 1, 2, 3 |
| Minimum deployment | watchOS 10.0 | Matches iOS 17+ iPhone target; required for `@Observable` |
| UI framework | SwiftUI | Consistent with iPhone app; no WatchKit extension needed on watchOS 10+ |

---

## HR Collection

| Decision | Choice | Rationale |
|---|---|---|
| HR framework | `HealthKit` — `HKWorkoutSession` + `HKLiveWorkoutBuilder` | Only reliable method for continuous background HR (Q1 — A) |
| Activity type | `HKWorkoutActivityType.running` | Best match for the app's target activity |
| Location type | `HKWorkoutSessionLocationType.outdoor` | Default; does not affect HR collection |
| HR sample type | `HKQuantityTypeIdentifier.heartRate` | Standard HR quantity type |
| HR unit | `HKUnit.count().unitDivided(by: .minute())` | Beats per minute |

### HR Extraction Pattern
```swift
func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
    guard collectedTypes.contains(HKQuantityType(.heartRate)) else { return }
    let bpm = workoutBuilder
        .statistics(for: HKQuantityType(.heartRate))?
        .mostRecentQuantity()?
        .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    guard let bpm else { return }
    onHRReading?(HRReading(value: Int(bpm)))
}
```

---

## HealthKit Persistence (Q1 — A)

| Decision | Choice | Rationale |
|---|---|---|
| Session end behavior | `builder.finishWorkout(completion:)` | Saves HR samples + duration to Apple Health |
| Activity rings contribution | Yes — automatic | `.running` activity type contributes to Move + Exercise rings |

```swift
func stop() {
    session?.end()
    builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
        self?.builder?.finishWorkout { _, _ in
            // Saved to Apple Health
        }
    }
}
```

---

## WatchConnectivity

| Decision | Choice | Rationale |
|---|---|---|
| HR send method | `sendMessage` | Real-time; symmetric with iPhone → Watch haptic flow |
| Failure handling | Fire-and-forget (silent `errorHandler`) | Consistent with Unit 3 decision; late HR worse than no HR |
| Command receipt | `session(_:didReceiveMessage:)` delegate | Receives workoutStarted, workoutStopped, haptic commands |

---

## Haptic Execution

| Decision | Choice | Rationale |
|---|---|---|
| Framework | `WatchKit` — `WKInterfaceDevice` | Built-in; no import needed beyond WatchKit |
| Execution | `WKInterfaceDevice.current().play(_:)` | Synchronous; fires immediately on call |
| Silent mode bypass | `.retry` type bypasses silent mode | Emergency stop must always be felt (Q4 — A) |

### HapticPattern → WKHapticType Mapping (Q4 — A)
```swift
switch pattern {
case .short:             WKInterfaceDevice.current().play(.notification)
case .long:              WKInterfaceDevice.current().play(.directionUp)
case .doubleTap:         WKInterfaceDevice.current().play(.success)
case .emergencyRepeated: WKInterfaceDevice.current().play(.retry)
}
```

---

## Frameworks Used (No SPM)

| Framework | Purpose |
|---|---|
| `HealthKit` | HKWorkoutSession, HKLiveWorkoutBuilder, HR samples |
| `WatchKit` | WKInterfaceDevice haptic playback |
| `WatchConnectivity` | WCSession iPhone ↔ Watch communication |

**SPM dependency**: `HeartRateCoachCore` — reused from Unit 1. Provides `HRReading`, `HapticPattern`, `CoachingMessage`, `PhaseType`.

No new external SPM packages in Unit 4.

---

## Entitlements Required

| Entitlement | Purpose |
|---|---|
| `com.apple.developer.healthkit` | HKWorkoutSession access |
| `com.apple.developer.healthkit.background-delivery` | Keep HR sensor active with screen off |

Both must be added to `HeartCoachWatch.entitlements` (new file).
