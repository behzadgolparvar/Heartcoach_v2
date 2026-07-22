# Unit Test Execution

## Test Suites Overview

| Suite | Target | Framework | Tests | Focus |
|---|---|---|---|---|
| HeartRateCoachCore | `HeartRateCoachCoreTests` | XCTest + SwiftCheck | ~35 | ZoneCalculator, CoachingEngine, PBT invariants |
| iPhone App | `HeartCoachTests` | XCTest | ~12 | WorkoutViewModel, Mocks |
| Watch App | `HeartCoachWatchTests` | XCTest | 3 | HapticService, RawValue decoding |

---

## Run HeartRateCoachCore Unit Tests

Tests the pure-Swift domain logic — no simulator required.

```bash
swift test \
    --package-path HeartRateCoachCore \
    --filter HeartRateCoachCoreTests
```

**Alternative (via xcodebuild):**
```bash
xcodebuild test \
    -project HeartCoach.xcodeproj \
    -scheme HeartRateCoachCore \
    -destination 'platform=macOS' \
    | xcpretty
```

**Expected:**
- All ZoneCalculator tests pass (boundary values, invalid inputs)
- All 11 CoachingEngine example-based tests pass
- All 9 PBT invariants pass (SwiftCheck runs 100 cases each by default)
- **Total: ~35 tests, 0 failures**

### Key test cases to verify:

| Test | What it checks |
|---|---|
| `testNoSignalTriggersNoSignalMessage` | `Int.max` → Layer 1 `.noSignal` |
| `testHRAboveZone5MaxTriggersEmergencyStop` | Emergency stop fires when HR > zone 5 max |
| `testWithin5PercentOfZone5MaxTriggersCriticalSlowDown` | Critical slow-down band |
| `testLayer2AntiSpam` | No second message within 20s |
| `testPBTLayer1AlwaysFiresFirst` | Layer 1 takes priority over Layer 2 in all generated inputs |
| `testPBTInZoneStreakNeverNegative` | `consecutiveInZoneSeconds` is always ≥ 0 |

---

## Run iPhone App Unit Tests

```bash
xcodebuild test \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoach \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -testPlan HeartCoach \
    | xcpretty
```

**If no test plan exists, run directly:**
```bash
xcodebuild test \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoach \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    | xcpretty
```

**Expected:**
- WorkoutViewModel mock-based tests pass
- MockVoiceFeedbackService captures spoken messages correctly
- MockWatchBridge captures sent haptics correctly
- **Total: ~12 tests, 0 failures**

### Key test cases to verify:

| Test | What it checks |
|---|---|
| `testStartBeginsTickLoop` | `start()` activates WatchBridge and starts ticking |
| `testEmergencyStopSpeaksCorrectMessage` | `.emergencyStop` spoken when HR > HRmax |
| `testPauseResumeClearsAntiSpam` | `resetForPause()` clears coaching state |
| `testSessionBuildsCorrectTimeInZones` | `buildSession()` computes per-zone seconds from HR records |

---

## Run Watch App Unit Tests

```bash
xcodebuild test \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoachWatchTests \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
    | xcpretty
```

**Expected:**
- All 4 `HapticPattern` rawValues decode correctly
- RawValue stability check passes (no accidental renames)
- `HapticService` instantiation smoke test passes
- **Total: 3 tests, 0 failures**

---

## Run All Tests (Combined)

```bash
# SPM package tests
swift test --package-path HeartRateCoachCore

# iPhone app tests
xcodebuild test \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoach \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    | xcpretty

# Watch tests
xcodebuild test \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoachWatchTests \
    -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' \
    | xcpretty
```

---

## Code Coverage

To enable coverage reporting:
```bash
xcodebuild test \
    -project HeartCoach.xcodeproj \
    -scheme HeartCoach \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -enableCodeCoverage YES \
    | xcpretty
```

View coverage in Xcode: **Product → Show Build Folder in Finder**, then open `.xcresult` in Xcode.

**Coverage targets:**
- `CoachingEngine`: ≥ 90% (PBT invariants provide high coverage)
- `ZoneCalculator`: ≥ 95%
- `WorkoutSessionManager`: ≥ 80%

---

## Troubleshooting

### `SwiftCheck: no such module`
```bash
cd HeartRateCoachCore && swift package resolve
```

### `No simulator named 'Apple Watch Series 9 (45mm)'`
List available simulators and pick an appropriate watchOS one:
```bash
xcrun simctl list devices available | grep Watch
```
Replace the destination string with an available Watch simulator name.

### Tests hang on WCSession (Watch tests)
`WKInterfaceDevice.current().play()` is a no-op in the simulator — this is expected. `HapticServiceTests` does not call `play()` directly; it only tests mapping logic and instantiation.
