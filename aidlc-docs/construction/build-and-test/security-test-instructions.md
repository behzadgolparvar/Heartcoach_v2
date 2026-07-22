# Security Test Instructions

Security Baseline extension is **enabled** for this project. All SECURITY rules listed here are blocking — the app must not ship if any fail.

---

## SECURITY-01: Authentication — Firebase Auth Required

**Rule**: All Firestore reads/writes must be gated behind Firebase Auth.

**Automated verification (Firestore Rules):**

Open Firebase Console → Firestore → Rules and verify:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /sessions/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Manual test:**
1. Using a REST client (curl or Postman), attempt to read from `sessions/{anyUID}` without an Authorization header
2. Expected: `403 PERMISSION_DENIED`

---

## SECURITY-02: `GoogleService-Info.plist` Not in Git

**Rule**: Firebase config file must never be committed to the repository.

```bash
# Verify not tracked
git ls-files HeartCoach/GoogleService-Info.plist
# Expected: no output (file is untracked)

# Verify gitignored
git check-ignore -v HeartCoach/GoogleService-Info.plist
# Expected: .gitignore:X:GoogleService-Info.plist  HeartCoach/GoogleService-Info.plist

# Verify not in any commit (scan full history)
git log --all --full-history -- HeartCoach/GoogleService-Info.plist
# Expected: no output (never committed)
```

**If found in history:** Rotate the Firebase API key immediately via Firebase Console before addressing the git history.

---

## SECURITY-03: No Health Data in Logs

**Rule**: HR values, age, RHR, and zone configuration must never appear in any log output.

**Automated search — scan all Swift files for logging of HR data:**
```bash
# Search for any log statements that might include HR values
grep -rn "print\|NSLog\|os_log\|Logger" \
    HeartCoach/ HeartCoachWatch/ HeartRateCoachCore/ \
    | grep -i "hr\|bpm\|heartrate\|zone\|age\|rhr" \
    | grep -v "//.*print\|//.*NSLog"
# Expected: no results (or only comments)
```

**Manual review:**
- `HRService.workoutBuilder(_:didCollectDataOf:)` — verify bpm value is passed to callback only, not logged
- `WatchSessionManager.sendHR(_:)` — verify `reading.value` is sent via WCSession only, not logged
- `WorkoutSessionManager.processTick()` — verify `hr` variable is used for computation only
- `SessionRepository` — verify Firestore documents do not include raw HR stream in production writes

---

## SECURITY-04: HealthKit Permissions — Minimal Scope

**Rule**: App requests only HealthKit types it actually uses.

**Verify in `HRService.start()`:**
- `toShare`: `heartRate` quantity type + `workoutType` — correct (Watch needs to write HR and workout)
- `toRead`: `heartRate` only — correct (Watch reads HR from sensor)

**Verify in iPhone target (if HealthKit is used):**
- HeartCoach iPhone app does NOT use HealthKit directly (HR comes via WCSession, not HealthKit)
- Verify `HeartCoach` target has **no** HealthKit framework dependency: `grep -i healthkit project.yml` should show it only in `HeartCoachWatch` target

```bash
grep -A5 "HeartCoach:" project.yml | grep -i healthkit
# Expected: no output (HeartCoach iPhone target has no HealthKit dependency)
```

---

## SECURITY-05: Input Validation — HR Values

**Rule**: External HR values (from WCSession) must be validated before use.

**Verify in `WatchBridge.session(_:didReceiveMessage:)`:**
```swift
guard let bpm = message["hr"] as? Int else { return }
```
The guard ensures only valid `Int` HR values are processed. Negative or impossibly large values are not explicitly rejected here — add a bounds check if strict validation is required:

**Recommended enhancement (optional, not blocking):**
```swift
guard let bpm = message["hr"] as? Int, bpm > 0, bpm < 300 else { return }
```

**Manual test:** Send a WCSession message with `["hr": -1]` from the Watch simulator — verify it is silently dropped and does not crash the app or corrupt `CoachingEngineState`.

---

## SECURITY-06: Dependency Vulnerability Scan

**Swift Package Manager — check for known vulnerabilities:**

```bash
# List all resolved packages and versions
cat HeartRateCoachCore/Package.resolved 2>/dev/null || \
    cat HeartCoach.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Manually check each dependency:
# - firebase-ios-sdk: check https://github.com/firebase/firebase-ios-sdk/releases for security advisories
# - SwiftCheck: check https://github.com/typelift/SwiftCheck/releases
```

**Expected:** No known CVEs for the pinned versions. Firebase SDK releases include security patches — use the latest `11.x` release.

---

## SECURITY-07: App Transport Security

**Rule**: All network traffic must use HTTPS.

**Verify in `HeartCoach/Info.plist`** (generated from `project.yml`):
- No `NSAppTransportSecurity` exception keys present
- Firebase SDK uses HTTPS by default — no exceptions needed

```bash
grep -i "NSAppTransportSecurity\|NSAllowsArbitraryLoads" HeartCoach/Info.plist 2>/dev/null
# Expected: no output
```

---

## Security Test Checklist

| Rule | Test Type | Status |
|---|---|---|
| SECURITY-01: Auth gating | Manual (Firestore Rules) | ☐ |
| SECURITY-02: No plist in git | Automated (git commands) | ☐ |
| SECURITY-03: No health data in logs | Automated (grep) | ☐ |
| SECURITY-04: Minimal HealthKit scope | Code review | ☐ |
| SECURITY-05: HR input validation | Manual / Code review | ☐ |
| SECURITY-06: Dependency scan | Manual | ☐ |
| SECURITY-07: App Transport Security | Automated (grep) | ☐ |

All items must be checked before the app is distributed.
