# NFR Requirements — Unit 4: Apple Watch App

## NFR Category Assessment

| Category | Applicable | Reason |
|---|---|---|
| Performance | Yes | HR delivery latency, haptic timing |
| Reliability | Yes | HKWorkoutSession background continuity, WCSession gap handling |
| Security | Yes | HR data on Watch — SECURITY-03 carries forward |
| Scalability | N/A | Single user, single session, on-device only |
| Availability | Yes | Background execution while Watch display off |
| Maintainability | N/A | Thin Watch app; PBT not applicable (partial enforcement covers ZoneCalculator + CoachingEngine only) |

---

## Performance Requirements

| Requirement | Target | Rationale |
|---|---|---|
| HR sample → WCSession send latency | < 500ms | HKLiveWorkoutBuilder callback to `sendMessage` call — pure local processing |
| WCSession send → iPhone receipt latency | < 200ms | Bluetooth delivery; consistent with Unit 3 haptic budget |
| Haptic execution latency (receive → play) | < 50ms | `WKInterfaceDevice.current().play()` is synchronous; fires on message receipt |
| Watch UI update after HR reading | < 16ms (one frame) | `viewModel.currentHR` updated on `@MainActor` |

**Note**: Total end-to-end latency (HR sensor → coaching cue spoken on iPhone) is approximately 5–6 seconds by design — the 5-second tick loop dominates. The Watch transmission latency above is well within that budget.

---

## Reliability Requirements

### HKWorkoutSession Background Continuity

The `HKWorkoutSession` must keep the HR sensor sampling even when the Watch display turns off (which happens after ~15 seconds of no interaction while running).

| Requirement | Detail |
|---|---|
| Background HR sampling | `HKWorkoutSession` keeps sensor active in background — no additional configuration needed |
| Session survival | Session persists through screen off, wrist-down, and brief app suspension |
| Recovery from suspension | If Watch OS briefly suspends the app, `HKWorkoutSession` wakes it when a new HR sample arrives |

### WCSession Gap Handling

| Scenario | Behaviour |
|---|---|
| iPhone reachable | HR sent immediately via `sendMessage` |
| iPhone not reachable (Bluetooth gap) | `sendHR()` guard fails silently — reading dropped |
| Reconnect | Next HR reading sent normally; iPhone staleness logic handles the gap |
| Haptic command arrives while Watch unreachable | N/A — iPhone only sends haptics when `isReachable` is true (checked in `WatchBridge`) |

### HealthKit Session End

| Scenario | Behaviour |
|---|---|
| Normal workout end | `builder.finishWorkout(completion:)` — saves to Apple Health (Q1 — A) |
| Emergency stop | `session.end()` → `builder.finishWorkout(completion:)` — also saves |
| App crash during workout | `HKWorkoutSession` recovers on next app launch via `HKHealthStore.recoverActiveWorkoutSession` |

---

## Security Requirements

All health data security rules from Unit 2 carry forward to the Watch target.

| Rule | Application to Unit 4 |
|---|---|
| SECURITY-03 (no health data in logs) | HR values from `HKLiveWorkoutBuilder` must never appear in `print()`, `os_log()`, or crash reports on the Watch |
| SECURITY-11 (health data classification) | HR samples on Watch are sensitive — not sent to any third party beyond iPhone via WCSession |
| SECURITY-15 (no raw errors to user) | WCSession errors silently dropped; no raw error shown on Watch UI |

---

## Availability Requirements

| Requirement | Detail |
|---|---|
| Background HR sensor | Guaranteed by `HKWorkoutSession` — this is its primary purpose |
| Background WCSession | WCSession `session(_:didReceiveMessage:)` fires even when app is backgrounded |
| No network dependency | Watch app is fully offline-capable — only Bluetooth to iPhone required |

---

## HealthKit Persistence (Q1 — A)

When the workout ends, `HKLiveWorkoutBuilder` saves the session to Apple Health:
- Activity type: `.running` (or `.other` if multi-sport is preferred — `.running` is clearest for the user)
- Metrics saved: HR samples, workout duration, start/end time
- Visible in: Apple Health app, Activity rings, any HealthKit-reading fitness app

`builder.finishWorkout(completion:)` is called instead of `builder.discardWorkout()`.

---

## PBT Compliance (Unit 4)

PBT extension does not apply to Unit 4. The partial enforcement mode (decided in Requirements Analysis) covers only `ZoneCalculator` and `CoachingEngine`. The Watch app contains no domain logic — it is a sensor + display only.

| Rule | Status |
|---|---|
| PBT-02 through PBT-09 | N/A — Watch app has no testable pure functions matching the criteria |

---

## Security Extension Compliance (Unit 4)

| Rule | Status | Notes |
|---|---|---|
| SECURITY-03 | Planned | No HR values in Watch logs |
| SECURITY-11 | Compliant | HR only transmitted to iPhone via local Bluetooth WCSession |
| SECURITY-15 | Compliant | WCSession errors silently dropped |
| All others | N/A | No auth, no network, no storage beyond HealthKit |
