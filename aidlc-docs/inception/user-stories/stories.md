# User Stories — HeartRateCoach

**Persona**: Alex — Active Fitness Enthusiast (see `personas.md`)
**Structure**: Hybrid — epics per feature area, stories per user action
**AC Format**: BDD (Given/When/Then) for logic-heavy stories; bullet-points for UI/screen stories

---

## Epic 1: Authentication & Onboarding

### US-01: Sign In with Apple
**As Alex, I want to sign in with my Apple ID, so that my data is private and I don't need to create another account.**

**Acceptance Criteria:**
- Sign in with Apple button is the primary and only auth option on the launch screen
- Successful sign-in creates a Firebase Auth user and navigates to Onboarding (first launch) or Home (returning user)
- Failed or cancelled sign-in returns to the launch screen with no error exposed
- User's Apple ID email is never displayed or stored in Firestore

---

### US-02: Complete My Profile
**As Alex, I want to enter my age, resting heart rate, and optional details during onboarding, so that the app can calculate my personal heart rate zones.**

**Acceptance Criteria:**
- Onboarding collects: age (required), resting HR (required), sex (optional), weight (optional)
- Age field accepts integers only; rejects letters and symbols
- RHR field accepts integers only in range 40–100 bpm
- RHR outside 40–100 shows warning: *"This value is outside the typical range. Please confirm it is correct."* — does not block progression
- Onboarding screen includes guidance text directing Alex to retrieve resting HR from Apple Health (morning value recommended)
- Tapping "Continue" without age or RHR shows inline validation errors; does not navigate forward

---

### US-03: Set My Fitness Goal and Preferred Workout
**As Alex, I want to choose my fitness goal and preferred workout type during onboarding, so that the app knows how to guide my training.**

**Acceptance Criteria:**
- Goal selector offers exactly two options: "Fat Burn" and "Endurance"
- Workout selector offers exactly three options: "Continuous", "HIIT", "Fartlek"
- Both selections are required before proceeding; tapping "Done" without selecting shows inline error
- Selections are saved to Firestore under `users/{userId}/settings`
- Both can be changed later in Settings

---

## Epic 2: HR Zone Setup

### US-04: View My Personalised HR Zones
**As Alex, I want to see my calculated heart rate zones immediately after onboarding, so that I understand what the zones mean for my body before I start training.**

**Acceptance Criteria:**
- After onboarding completes, zones screen displays all 5 zones with bpm ranges and zone names
- Zone ranges are calculated using the Karvonen formula with the values Alex entered
- Zone labels displayed: Zone 1 Recovery, Zone 2 Easy / Fat Burn, Zone 3 Aerobic, Zone 4 Threshold, Zone 5 Max Effort
- A brief explanation of Karvonen personalisation is shown ("These zones are calculated from your age and resting heart rate")

---

### US-05: See Zones Recalculate When I Update My Profile
**As Alex, I want my HR zones to update automatically when I change my age or resting HR in Settings, so that my coaching stays accurate over time.**

**Acceptance Criteria:**
- Saving a new age or RHR value in Settings immediately triggers zone recalculation
- Updated zones are written to Firestore under `users/{userId}/hr_zones`
- Settings screen shows the updated zone ranges after saving
- No app restart required for new zones to take effect in the coaching engine

---

## Epic 3: Workout Execution

### US-06: Select and Start a Workout
**As Alex, I want to select a workout type from the Home screen and start it, so that I can begin a coached training session.**

**Acceptance Criteria:**
- Home screen shows the three workout types with a brief description of each
- Previously preferred workout type is pre-selected based on settings
- Tapping "Start" launches the Workout Active screen on iPhone and activates the Watch app
- HKWorkoutSession is started on the Watch before the first coaching tick fires
- If Apple Watch is not reachable, a warning is shown: *"Apple Watch not connected. HR coaching requires your Watch."* — workout cannot start without Watch

---

### US-07: See Live Workout Data During a Session
**As Alex, I want to see my live heart rate, current zone, and phase timer during the workout, so that I always know where I am in the session.**

**Acceptance Criteria (iPhone):**
- Workout Active screen shows: current HR (bpm), current zone number and name, target zone for current phase, time remaining in current phase, total elapsed time, current coaching message
- Display updates every 5 seconds as new HR readings arrive
- Phase name is shown (Warm-up / Exercise / Recovery / Cool-down)

**Acceptance Criteria (Apple Watch):**
- Watch Workout Active screen shows: current HR, current zone, target zone, phase indicator
- Watch display updates every 5 seconds in sync with iPhone
- Watch remains visible during workout (always-on display supported where available)

---

### US-08: Receive Coaching Cues When I'm Out of Zone
**As Alex, I want to hear a voice cue and feel a haptic on my Watch when my heart rate is outside the target zone, so that I can adjust my effort without looking at my phone.**

**Acceptance Criteria (BDD):**

**Scenario: HR below target zone**
```
Given the coaching engine is in the Zone Coaching layer (10-sec tick)
And HR_smooth < target_zone_min
And the last "Speed up" cue was more than 20 seconds ago
When the coaching tick fires
Then AVSpeechSynthesizer says "Speed up"
And WatchConnectivity sends a short haptic command to the Watch
```

**Scenario: HR above target zone**
```
Given the coaching engine is in the Zone Coaching layer (10-sec tick)
And HR_smooth > target_zone_max
And the last "Slow down" cue was more than 20 seconds ago
When the coaching tick fires
Then AVSpeechSynthesizer says "Slow down"
And WatchConnectivity sends a long haptic command to the Watch
```

**Scenario: HR within target zone**
```
Given HR_smooth is between target_zone_min and target_zone_max (inclusive)
When the coaching tick fires
Then no voice cue is played
And no haptic is sent
```

**Scenario: Anti-spam rule**
```
Given the last coaching cue was "Speed up" 15 seconds ago
And HR_smooth is still below target_zone_min
When the coaching tick fires at 10-second interval
Then no cue is played (20-second cooldown not yet expired)
```

---

### US-09: Receive Positive Feedback for Sustained Zone Effort
**As Alex, I want to hear "Good job, keep going" when I've stayed in my target zone for 30 seconds, so that I feel encouraged when I'm training correctly.**

**Acceptance Criteria (BDD):**

**Scenario: Positive feedback triggered**
```
Given the user has been continuously in the target zone for 30 seconds
When the positive feedback condition is evaluated
Then AVSpeechSynthesizer says "Good job, keep going"
And WatchConnectivity sends a double-tap haptic to the Watch
```

**Scenario: Streak broken — no false positive**
```
Given the user has been in target zone for 25 seconds
And HR_smooth briefly exits the target zone for one 5-second reading
When positive feedback condition is evaluated
Then the 30-second streak counter resets
And no positive feedback is delivered
```

---

### US-10: Workout Stops Safely When HR Exceeds Maximum
**As Alex, I want the app to stop my workout and warn me immediately if my heart rate goes above my estimated maximum, so that I'm protected from overexertion.**

**Acceptance Criteria (BDD):**

**Scenario: Emergency stop triggered**
```
Given the safety layer fires every 5 seconds (highest priority)
And current_HR > HRmax (220 - age)
When the safety check runs
Then the workout is immediately stopped
And AVSpeechSynthesizer says "Your heart rate is above your estimated maximum. Stop exercising and check your condition."
And WatchConnectivity sends a strong repeated haptic command
And an emergency event is written to Firebase
And the Emergency Stop screen is shown on Apple Watch (full-screen warning)
```

**Scenario: Safety layer active during grace period**
```
Given a HIIT or Fartlek interval has just started (within the 10-second grace period)
And current_HR > HRmax
When the safety check runs
Then the emergency stop still triggers (grace period does not suppress Layer 1)
```

---

### US-11: No Coaching Interruptions During Phase Transitions
**As Alex, I want coaching cues to be suppressed for the first 10 seconds of each new phase in HIIT and Fartlek, so that I have time to change pace before being evaluated.**

**Acceptance Criteria (BDD):**

**Scenario: Grace period suppresses zone coaching**
```
Given a HIIT or Fartlek phase transition has just occurred
And fewer than 10 seconds have elapsed since the transition
And HR_smooth is outside the new target zone
When the Zone Coaching layer (Layer 2) evaluates
Then no voice cue is played
And no haptic is sent
```

**Scenario: Grace period does not apply to Continuous training**
```
Given the workout type is Continuous
And a new cycle phase has started
When the Zone Coaching layer evaluates
Then normal zone evaluation applies immediately (no grace period)
```

---

### US-12: Stop a Workout Early
**As Alex, I want to be able to stop my workout before it finishes, so that I can end a session if I need to.**

**Acceptance Criteria:**
- A "Stop Workout" button is accessible at all times on the Workout Active screen
- Tapping Stop shows a confirmation prompt: *"End workout? Your session so far will be saved."*
- Confirming ends the HKWorkoutSession, saves the partial session to Firebase, and navigates to Session Summary
- Cancelling returns to the active workout without interruption

---

## Epic 4: Apple Watch Experience

### US-13: See Coaching Overlay on Zone Transition (Watch)
**As Alex, I want my Apple Watch to announce the new zone when a phase transition occurs, so that I know what effort level is expected without looking at my iPhone.**

**Acceptance Criteria:**
- At each phase transition, the Watch displays a full-screen coaching overlay for 3 seconds
- Overlay shows: new zone number, zone name, and a coaching style cue (e.g. "Zone 3 — Aerobic. Change pace.")
- After 3 seconds, overlay dismisses and returns to the Workout Active watch screen
- Coaching overlay is shown for all three workout types at each phase transition

---

### US-14: See Emergency Stop Warning on Watch
**As Alex, I want my Apple Watch to show a full-screen emergency warning when my heart rate exceeds my maximum, so that I get an unmissable alert on my wrist.**

**Acceptance Criteria (BDD):**

```
Given the safety layer has triggered an emergency stop
When the WatchConnectivity command is received by the Watch
Then the Watch displays a full-screen Emergency Stop screen
And the screen shows the message: "Heart rate too high — stop exercising"
And the strong repeated haptic pattern fires on the Watch
And the Emergency Stop screen remains visible until the user dismisses it
And dismissing the screen navigates to the Watch home (not back to workout)
```

---

## Epic 5: Post-Workout & Session Summary

### US-15: View My Session Summary After a Workout
**As Alex, I want to see a summary of my workout immediately after it ends, so that I can understand how the session went.**

**Acceptance Criteria:**
- Session Summary screen is shown automatically after workout ends (normally or via early stop)
- Summary displays: workout type, total duration, average HR, time spent in each zone (seconds and percentage), date and time
- Zone breakdown is shown as both a bar chart and numeric values
- A "Done" button returns to the Home screen

---

## Epic 6: Session Persistence

### US-16: Session Saved to Firebase on Workout Completion
**As Alex, I want my completed session to be automatically saved to my account, so that I have a permanent record of every workout.**

**Acceptance Criteria:**
- On workout completion, a `sessions` document is written to `users/{userId}/sessions/{sessionId}` with: date, type, duration_sec, avg_hr, time_in_zones
- The `hr_stream` subcollection is populated with one record every 5 seconds during the active workout
- Firebase writes are fire-and-forget — they do not block the coaching engine or UI
- If the session saves successfully, no notification is shown (silent background operation)

---

### US-17: Session Saved Locally When Offline, Synced Automatically
**As Alex, I want my session to be saved to my phone when I have no internet connection, and automatically uploaded when I reconnect, so that I never lose a workout.**

**Acceptance Criteria:**
- When workout ends and Firebase is unreachable, the session summary is queued in local storage (Core Data / UserDefaults)
- The Session Summary screen shows a banner: *"Session saved locally — will sync when connected"*
- When network connectivity is restored, the app automatically syncs all queued sessions to Firestore in the background
- After successful sync, a brief notification or banner confirms: *"Session synced"*
- No duplicate session documents are created if a sync is retried
- Live `hr_stream` writes during the workout are best-effort — only the final session summary is queued offline

---

## Epic 7: History

### US-18: View My Past Sessions
**As Alex, I want to see a list of all my completed workouts, so that I can track my training history over time.**

**Acceptance Criteria:**
- History screen shows all past sessions in reverse chronological order
- Each row shows: date, workout type, duration, average HR
- Sessions synced from local queue appear in the list once uploaded
- Tapping a session navigates to its Session Summary detail view
- An empty state message is shown when no sessions exist yet

---

## Epic 8: Settings

### US-19: Update My Profile and Resting HR
**As Alex, I want to update my age and resting heart rate in Settings, so that my HR zones stay accurate as my fitness improves.**

**Acceptance Criteria:**
- Settings screen displays current values for: age, resting HR, sex, weight
- Saving new age or RHR immediately triggers zone recalculation (see US-05)
- RHR outside 40–100 shows the same out-of-range warning as onboarding but does not block saving
- Updated values are written to Firestore under `users/{userId}/profile` and `users/{userId}/physiology`

---

### US-20: Update My Fitness Goal and Preferred Workout
**As Alex, I want to change my training goal and default workout type in Settings, so that the app reflects my current training focus.**

**Acceptance Criteria:**
- Settings screen shows current goal and preferred workout selections
- Changing either updates the Firestore `settings` document immediately on save
- Updated preferred workout is reflected as the pre-selected option on the Home screen next time Alex opens it

---

## Story Summary

| Epic | Stories | AC Format |
|---|---|---|
| Authentication & Onboarding | US-01, US-02, US-03 | Bullet-points |
| HR Zone Setup | US-04, US-05 | Bullet-points |
| Workout Execution | US-06, US-07, US-08, US-09, US-10, US-11, US-12 | Mixed (BDD for US-08–11, bullet for rest) |
| Apple Watch Experience | US-13, US-14 | Mixed (BDD for US-14) |
| Post-Workout & Session Summary | US-15 | Bullet-points |
| Session Persistence | US-16, US-17 | Bullet-points (US-17 is the offline story) |
| History | US-18 | Bullet-points |
| Settings | US-19, US-20 | Bullet-points |
| **Total** | **20 stories** | |
