# Integration Test Instructions

## Purpose

Verify that the four units work correctly together end-to-end. Unlike unit tests (which use mocks), integration tests exercise real connections between components.

> **Note**: Most integration tests require physical hardware (iPhone + Apple Watch) or Firebase emulator. Simulator-only tests are marked [SIM].

---

## Integration Scenarios

### Scenario 1: CoachingEngine → WorkoutSessionManager → VoiceFeedback [SIM]

Tests that coaching decisions correctly drive audio output within a real `WorkoutSessionManager` (non-mocked voice).

**Setup:**
- iOS Simulator (iPhone 15 Pro or newer)
- No Apple Watch required

**Test Steps:**
1. Create a `WorkoutSessionManager` with a real `VoiceFeedbackService` and a stubbed `WatchBridge` (that accepts messages but doesn't relay to Watch)
2. Feed a simulated HR reading above zone 5 max (`hrRecords` with value > `zones.zone5.max`)
3. Trigger `processTick()` manually
4. Verify `VoiceFeedbackService.isSpeaking` becomes true and the spoken text contains "stop"

**Expected:** Layer 1 emergency stop fires, audio synthesis begins, correct message spoken.

---

### Scenario 2: WorkoutSessionManager → WatchBridge → WCSession [DEVICE REQUIRED]

Tests the full message pipeline from iPhone coaching engine to Apple Watch display.

**Hardware:** iPhone + paired Apple Watch running HeartCoachWatch

**Setup:**
1. Build and install `HeartCoach` on iPhone
2. Build and install `HeartCoachWatch` on paired Watch
3. Ensure both devices are on the same WiFi or in Bluetooth range

**Test Steps:**
1. Open HeartCoach on iPhone and log in
2. Complete onboarding (set age, RHR, goal, zones)
3. Tap "Start Workout" → select Continuous program
4. Observe Apple Watch:
   - Watch screen transitions from **IdleWatchView** ("Start workout on iPhone") to **WorkoutWatchView** (HR + zone display)
   - HR readings stream from Watch to iPhone (visible in workout view)
   - Zone color on Watch matches zone color on iPhone
5. When coaching message fires (after 10s in wrong zone): verify Watch displays the message text

**Expected:**
- `workoutStarted` command reaches Watch within 2s of iPhone start
- HR streams from Watch to iPhone at ~5s intervals
- Coaching state (`zone`, `phase`, `message`) reaches Watch within 5s of each tick

---

### Scenario 3: HRService Recovery After Watch App Suspension [DEVICE REQUIRED]

Tests that the Watch app recovers an active `HKWorkoutSession` after watchOS suspends the app.

**Hardware:** iPhone + paired Apple Watch

**Test Steps:**
1. Start a workout on iPhone (Watch begins HR collection)
2. On the Watch, press the crown to go to the watch face (simulating app suspension)
3. Wait 30 seconds
4. Tap the HeartCoachWatch app to bring it back to foreground
5. Verify: `WatchSessionManager.recoverIfNeeded()` reattaches to the active `HKWorkoutSession`, Watch UI shows correct HR, no gap in data collection

**Expected:** Session recovery within 3s of app re-entering foreground.

---

### Scenario 4: Firebase Authentication + Firestore Save [SIM or DEVICE]

Tests the full save pipeline from workout summary to Firestore.

**Option A — Firebase Emulator (recommended for CI):**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulators (Auth + Firestore)
firebase emulators:start --only auth,firestore
```

In `AppContainer.swift`, configure the emulator hosts before running tests:
```swift
// Add to AppContainer.init() for emulator testing only
Auth.auth().useEmulator(withHost: "localhost", port: 9099)
let settings = FirestoreSettings()
settings.host = "localhost:8080"
settings.cacheSettings = MemoryCacheSettings()
settings.isSSLEnabled = false
Firestore.firestore().settings = settings
```

**Option B — Live Firebase (requires Google account):**
Use the configured `GoogleService-Info.plist` pointing to a test Firebase project.

**Test Steps:**
1. Log in with email/password (create test account via Firebase Console or emulator UI)
2. Complete a short workout (~1 minute)
3. Tap "Save" on the workout summary screen
4. Open Firebase Console → Firestore → `sessions` collection
5. Verify a document exists with correct `userID`, `date`, `avgHR`, `timeInZones`

**Expected:**
- Session document created in Firestore under `sessions/{userID}/{sessionID}`
- `avgHR`, `durationSec`, `timeInZones` values match what was shown in the summary screen
- `syncStatus` field shows `"synced"`

---

### Scenario 5: Offline Queue → Sync on Reconnect [SIM]

Tests that sessions saved offline are synced when connectivity is restored.

**Test Steps:**
1. Enable Airplane Mode on iPhone simulator (`Settings → Airplane Mode`)
2. Complete and save a workout (verify "Saved locally" status in UI)
3. Disable Airplane Mode
4. Wait up to 30s for the offline queue processor to retry
5. Verify session appears in Firestore

**Expected:** `OfflineQueue` (Core Data) retries Firestore write and document appears within 30s.

---

## Setup Checklist

Before running device integration tests:

- [ ] iPhone and Apple Watch are paired and on the same Apple ID
- [ ] HealthKit permissions granted on both devices
- [ ] `GoogleService-Info.plist` in place
- [ ] Developer signing configured (real device requires paid Developer account)
- [ ] WCSession reachability confirmed (both devices unlocked, app in foreground)

---

## Cleanup After Tests

If using Firebase Emulator:
```bash
# Stop emulators (Ctrl+C or)
firebase emulators:stop
```

If using live Firebase (test project):
- Manually delete test documents from Firestore Console
- Delete test user from Authentication Console

---

## Known Limitations

| Limitation | Reason | Workaround |
|---|---|---|
| WCSession cannot be tested in unit tests | Requires two paired physical devices | Integration test on real hardware |
| `HKWorkoutSession` on Watch simulator is limited | watchOS simulator has limited HealthKit support | Test session recovery on real Watch |
| `AVSpeechSynthesizer` is silent in simulator by default | iOS Simulator mutes audio | Connect headphones or test on device |
