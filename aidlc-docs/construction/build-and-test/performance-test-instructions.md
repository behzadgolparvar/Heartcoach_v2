# Performance Test Instructions

## Performance Requirements

| Component | Requirement | Rationale |
|---|---|---|
| `CoachingEngine.tick()` | < 1ms per call | Called every 5s; must not block main thread |
| HR zone classification | < 0.1ms per call | Called on every tick and in SwiftUI render |
| Firestore session save | < 3s on good connection | User waits on summary screen |
| Offline queue retry | < 30s after reconnect | Acceptable UX delay |
| Watch → iPhone HR message latency | < 2s | Real-time coaching requires prompt HR |

---

## XCTest Performance Tests

Add these test methods to `HeartRateCoachCoreTests` to validate engine performance.

### CoachingEngine Tick Performance

Create or append to `HeartRateCoachCore/Tests/HeartRateCoachCoreTests/PerformanceTests.swift`:

```swift
import XCTest
import HeartRateCoachCore

final class PerformanceTests: XCTestCase {

    private let zones = HRZones(
        zone1: ZoneRange(min: 95, max: 114),
        zone2: ZoneRange(min: 115, max: 133),
        zone3: ZoneRange(min: 134, max: 152),
        zone4: ZoneRange(min: 153, max: 171),
        zone5: ZoneRange(min: 172, max: 190)
    )

    func testCoachingEngineTick_performance() {
        var state = CoachingEngineState()
        let phase = WorkoutPhase(type: .exercise, duration: 300, targetZone: 3, index: 1)

        measure {
            for _ in 0..<1000 {
                _ = CoachingEngine.tick(
                    hr: 145,
                    phase: phase,
                    elapsedInPhase: 30,
                    state: &state,
                    zones: zones,
                    now: Date()
                )
            }
        }
        // XCTest measure block fails if average > 10x the baseline
        // With < 1ms target: 1000 calls should complete in < 1s total
    }

    func testZoneClassification_performance() {
        measure {
            for hr in 90...200 {
                _ = try? ZoneCalculator.classify(hr: hr, zones: zones)
            }
        }
    }
}
```

**Run performance tests:**
```bash
swift test \
    --package-path HeartRateCoachCore \
    --filter PerformanceTests
```

**Expected:** Both measure blocks complete well within XCTest's default 10x baseline threshold. On modern hardware, 1000 `CoachingEngine.tick()` calls should complete in < 50ms total.

---

## Profiling in Xcode Instruments

For real-device profiling of the full workout session:

### Time Profiler — Tick Loop

1. Open `HeartCoach.xcodeproj` in Xcode
2. **Product → Profile** (or Cmd+I)
3. Select **Time Profiler** instrument
4. Run on a real iPhone
5. Start a workout and let it run for 2 minutes
6. Stop profiling and inspect the call tree
7. Filter by `processTick` — verify it is never the top CPU consumer

**Expected:** `processTick()` should appear as < 0.1% of total CPU time.

### Memory — No Leaks During Workout

1. Use **Leaks** instrument with the same workflow
2. Start/pause/resume a workout, then end it
3. Verify no leaked objects in `WorkoutSessionManager`, `CoachingEngineState`, or `VoiceFeedbackService`

**Expected:** Zero leaks. `WorkoutSessionManager` is deallocated fully after `end()` is called and `WorkoutViewModel` releases its reference.

---

## WCSession Latency

WCSession message latency cannot be measured programmatically in tests; use this manual procedure:

**Setup:** iPhone + paired Watch, both with HeartCoach apps installed.

**Procedure:**
1. Start a workout on iPhone
2. On Watch: note time of first HR measurement
3. On iPhone: note time the same HR value appears in WorkoutView
4. Calculate delta

**Expected latency:** < 2s end-to-end (Watch sensor → HRService callback → WCSession → iPhone WorkoutSessionManager → UI).

---

## Firestore Write Latency

**Manual test:**
1. Start a workout, run for 1 minute
2. Tap "Save" on the summary screen
3. Open Firebase Console in a browser tab (pre-loaded)
4. Note the time from "Save" tap to document appearing in Firestore

**Expected:** < 3s on a good WiFi connection.

---

## Notes

- `CoachingEngine.tick()` is a pure value-type operation with no allocation — it should be extremely fast
- The tick loop uses `Task.sleep(5_000_000_000)` — a 5-second interval — so per-tick latency has no user-visible impact as long as each tick completes in < 1s
- `AVSpeechSynthesizer.speak()` is asynchronous; it never blocks the tick loop
- Firebase SDK handles network latency internally with an offline persistence layer
