# Build and Test Summary

## Project Overview

| Item | Value |
|---|---|
| App Name | HeartCoach (iPhone) + HeartCoachWatch (Apple Watch) |
| Language | Swift 5.9, SwiftUI |
| Platforms | iOS 17+, watchOS 10+ |
| Build Tool | XcodeGen → xcodebuild |
| Test Frameworks | XCTest, SwiftCheck (PBT) |
| Firebase | Auth + Firestore |
| Security Extension | Enabled (all SECURITY rules blocking) |
| PBT Extension | Partial (ZoneCalculator + CoachingEngine) |

---

## Units Delivered

| Unit | Target | Status |
|---|---|---|
| Unit 1 — HeartRateCoachCore | SPM package | Complete |
| Unit 2 — iPhone Foundation | HeartCoach (iOS) | Complete |
| Unit 3 — iPhone Workout Engine | HeartCoach (iOS) | Complete |
| Unit 4 — Apple Watch App | HeartCoachWatch (watchOS) | Complete |

---

## Build Instructions

See [build-instructions.md](build-instructions.md)

**Prerequisites to verify before first build:**
- [ ] Xcode 15.4+ installed
- [ ] `xcodegen` installed (`brew install xcodegen`)
- [ ] `GoogleService-Info.plist` placed at `HeartCoach/GoogleService-Info.plist`
- [ ] `DEVELOPMENT_TEAM` set in `project.yml`
- [ ] `xcodegen generate` run to create `HeartCoach.xcodeproj`

---

## Test Execution Summary

### Unit Tests
See [unit-test-instructions.md](unit-test-instructions.md)

| Suite | Tests | Coverage Target | Notes |
|---|---|---|---|
| HeartRateCoachCoreTests | ~35 | CoachingEngine ≥ 90%, ZoneCalculator ≥ 95% | Includes 9 PBT invariants via SwiftCheck |
| HeartCoachTests | ~12 | WorkoutSessionManager ≥ 80% | Mock-based; no network/device required |
| HeartCoachWatchTests | 3 | HapticService basics | Smoke tests; `WKInterfaceDevice.play()` not callable in test host |
| **Total** | **~50** | — | All can run in simulator |

### Integration Tests
See [integration-test-instructions.md](integration-test-instructions.md)

| Scenario | Requirement | Notes |
|---|---|---|
| CoachingEngine → VoiceFeedback | Simulator | Non-mocked voice integration |
| WCSession message pipeline | iPhone + Watch | Full HR stream + coaching state relay |
| HKWorkoutSession recovery | iPhone + Watch | App suspension/resume |
| Firebase Auth + Firestore save | Simulator + Emulator/Live | Full save pipeline |
| Offline queue sync | Simulator | Airplane mode test |

### Performance Tests
See [performance-test-instructions.md](performance-test-instructions.md)

| Component | Target | Test Method |
|---|---|---|
| `CoachingEngine.tick()` | < 1ms | XCTest `measure {}` (1000 iterations) |
| Zone classification | < 0.1ms | XCTest `measure {}` |
| Firestore write | < 3s | Manual timing |
| WCSession HR latency | < 2s | Manual timing on device |

### Security Tests
See [security-test-instructions.md](security-test-instructions.md)

| Rule | Status |
|---|---|
| SECURITY-01: Auth gating (Firestore Rules) | ☐ Verify before TestFlight |
| SECURITY-02: No `GoogleService-Info.plist` in git | ☐ Run git check commands |
| SECURITY-03: No health data in logs | ☐ Run grep scan |
| SECURITY-04: Minimal HealthKit scope | ☐ Code review |
| SECURITY-05: HR input validation | ☐ Code review + manual test |
| SECURITY-06: Dependency vulnerability scan | ☐ Manual check |
| SECURITY-07: App Transport Security | ☐ Run grep scan |

---

## Key Architecture Decisions (for test context)

| Decision | Impact on Testing |
|---|---|
| `CoachingEngine` is a pure static function | Fully testable without any setup; PBT-friendly |
| `CoachingEngineState` is a value type | PBT generators can produce arbitrary states |
| `WorkoutSessionManager` uses constructor injection | All dependencies are mockable |
| `WatchBridge` has a protocol | `MockWatchBridge` captures all outgoing messages |
| `Int.max` as stale HR sentinel | Easily tested — pass `Int.max` and verify Layer 1 fires |
| `now: Date` injected into `CoachingEngine.tick()` | Deterministic timing tests without sleep |

---

## Overall Readiness

| Category | Automated | Manual Required |
|---|---|---|
| Unit tests | Yes — run before every commit | No |
| Integration tests | Partial (Firebase emulator) | WCSession + Watch hardware |
| Performance tests | XCTest measure blocks | Instruments profiling |
| Security tests | Grep scans (SECURITY-02, 03, 07) | Firestore rules (SECURITY-01) |

**Ready for Operations / TestFlight when:**
- [ ] All ~50 unit tests pass
- [ ] WCSession pipeline verified on real devices
- [ ] All 7 security rules checked off
- [ ] `GoogleService-Info.plist` confirmed absent from git history
