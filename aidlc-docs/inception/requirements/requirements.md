# Requirements Document — HeartRateCoach

## Intent Analysis

| Attribute | Value |
|---|---|
| **User Request** | Build a native iPhone + Apple Watch app for real-time heart rate zone coaching during structured workouts |
| **Request Type** | New Project (Greenfield) |
| **Scope** | Cross-system — iOS app, watchOS app, shared SPM package, Firebase backend |
| **Complexity** | Complex — multi-platform native development, real-time sensor data, on-device coaching engine, HealthKit, WatchConnectivity, Firebase Auth + Firestore |
| **Requirements Depth** | Comprehensive |

---

## Clarified Decisions (from requirement-verification-questions.md)

| # | Topic | Decision |
|---|---|---|
| 1 | Firebase project | New project — provisioned from scratch as part of build |
| 2 | Apple Developer account | Active account available — signing and provisioning ready |
| 3 | Shared code structure | Local SPM package (`HeartRateCoachCore`) for `Shared/` code |
| 4 | Visual design | Dark mode primary |
| 5 | Watch face complication | Not in v1 — users launch from app icon |
| 6 | Voice feedback routing | iPhone speaker only (covers AirPods + wired earphones) |
| 7 | Offline session handling | Queue locally + sync to Firebase when connection restored (overrides original brief) |
| 8 | Security extension | Enabled — all SECURITY rules enforced as blocking constraints |
| 9 | PBT extension | Partial — PBT-02, PBT-03, PBT-07, PBT-08, PBT-09 enforced for ZoneCalculator and CoachingEngine only |

---

## Functional Requirements

### FR-01: User Onboarding & Profile

- FR-01.1: App MUST collect `age` (required) and `resting_hr` (required) during first-launch onboarding
- FR-01.2: App MUST collect optional `sex` and `weight` during onboarding
- FR-01.3: Onboarding MUST guide user to retrieve resting HR from Apple Health (morning resting value)
- FR-01.4: Accepted RHR range is 40–100 bpm; values outside this range MUST show a warning prompt
- FR-01.5: App MUST collect `goal` ("fat_burn" | "endurance") and `preferred_workout` ("continuous" | "hiit" | "fartlek") during onboarding
- FR-01.6: All profile data MUST be persisted to Firebase Firestore under the authenticated user's document

### FR-02: Heart Rate Zone Calculation

- FR-02.1: HRmax MUST be calculated as `220 - age`
- FR-02.2: HR Reserve (HRR) MUST be calculated as `HRmax - resting_hr`
- FR-02.3: Five HR zones MUST be calculated using the Karvonen formula:
  - Zone 1 (Recovery): 50–60% HRR
  - Zone 2 (Easy / Fat Burn): 60–70% HRR
  - Zone 3 (Aerobic): 70–80% HRR
  - Zone 4 (Threshold): 80–90% HRR
  - Zone 5 (Max Effort): 90–100% HRR
- FR-02.4: Zones MUST be recalculated whenever `age` or `resting_hr` is updated

### FR-03: Workout Programs

- FR-03.1: App MUST support three hardcoded 35-minute workout programs: Continuous, HIIT, and Fartlek
- FR-03.2: **Continuous Training** MUST implement:
  - 5-min warm-up (2 min Zone 1, 3 min Zone 2)
  - 5 training cycles: each = 5 min run (zones: Z2, Z3, Z3, Z3, Z4) + 1 min walk recovery (no HR enforcement)
  - Optional cool-down (2–5 min walk + ~5 min stretching prompts)
- FR-03.3: **HIIT Training** MUST implement:
  - 5-min warm-up (2 min Zone 1, 3 min Zone 2)
  - 15 cycles: each = 1 min HIGH (Z3 for cycles 1–3, Z4 for 4–12, Z5 for 13–15) + 1 min recovery walk (Z1–2, not enforced)
  - First 10 seconds of each interval: grace period — no coaching feedback
  - Safety cue during recovery if HR very high: *"Slow your walk"*
  - Optional cool-down
- FR-03.4: **Fartlek Training** MUST implement:
  - 5-min warm-up (2 min Zone 1, 3 min Zone 2)
  - 15 × 2-min segments in sequence: `2–3–2–3–4–2–3–4–3–4–3–4–2–3–5`
  - First 10 seconds of each segment: grace period — no coaching feedback
  - No dedicated recovery phases (recovery embedded in Zone 2 segments)
  - Optional cool-down

### FR-04: Real-Time Coaching Engine (on-device, iPhone)

- FR-04.1: HR data MUST arrive every 5 seconds from Apple Watch via HKWorkoutSession → WatchConnectivity
- FR-04.2: **Layer 1 — Safety** (runs every 5 sec, highest priority):
  - IF `current_HR > HRmax`: stop workout immediately, play voice cue, trigger strong repeated haptic, save emergency event to Firebase
- FR-04.3: **Layer 2 — Zone Coaching** (runs every 10 sec):
  - Smooth HR using average of last 2–3 readings
  - IF `HR_smooth < target_zone_min`: cue "Speed up", short haptic
  - IF `HR_smooth > target_zone_max`: cue "Slow down", long haptic
  - IF within zone: no correction
  - Anti-spam: do NOT repeat same message within 20 seconds
- FR-04.4: **Layer 3 — Positive Feedback** (condition-based):
  - IF user stays in target zone continuously for 30 sec: cue "Good job, keep going", double-tap haptic
- FR-04.5: Grace period (HIIT + Fartlek): first 10 seconds of each phase — suppress Layer 2 and Layer 3 feedback; Layer 1 (safety) remains active

### FR-05: Voice Feedback

- FR-05.1: Voice feedback MUST be delivered via `AVSpeechSynthesizer` on iPhone
- FR-05.2: Audio routes to iPhone speaker or connected audio device (AirPods, wired earphones) — no Watch speaker involvement

### FR-06: Haptic Feedback (Apple Watch)

- FR-06.1: Haptic commands MUST be sent from iPhone to Watch via WatchConnectivity reply
- FR-06.2: Haptic mapping:
  - Speed up → short vibration
  - Slow down → long vibration
  - Good job → double tap
  - Emergency stop → strong repeated vibration

### FR-07: WatchConnectivity Data Flow

- FR-07.1: Watch sends HR readings every 5 seconds to iPhone via `WCSession.sendMessage`
- FR-07.2: iPhone CoachingEngine processes HR, runs all 3 layers, and replies with coaching commands
- FR-07.3: Watch receives reply and executes haptic feedback
- FR-07.4: App MUST handle watch disconnection gracefully — continue session on iPhone, sync state when reconnected

### FR-08: iPhone App Screens

- FR-08.1: **Onboarding** — collect age, RHR (with Health guidance), sex, weight, goal, preferred workout
- FR-08.2: **Home** — select workout type, view last session summary
- FR-08.3: **Workout Active** — live HR display, current zone, phase timer, coaching messages
- FR-08.4: **Session Summary** — post-workout stats: time in zones, avg HR, duration
- FR-08.5: **History** — list of past sessions
- FR-08.6: **Settings** — edit profile, RHR, goal, preferred workout

### FR-09: Apple Watch App Screens

- FR-09.1: **Workout Active** — live HR, current zone, target zone, phase indicator
- FR-09.2: **Coaching Overlay** — zone transition announcement
- FR-09.3: **Emergency Stop** — full-screen warning when HR > HRmax

### FR-10: Firebase Data Persistence

- FR-10.1: User profile, physiology, HR zones, and settings MUST be stored in Firestore under `users/{userId}`
- FR-10.2: Each completed session MUST be saved to `users/{userId}/sessions/{sessionId}`
- FR-10.3: HR time-series MUST be saved to `users/{userId}/sessions/{sessionId}/hr_stream/{recordId}` every 5 seconds during workout
- FR-10.4: Authentication MUST use Firebase Auth with Sign in with Apple
- FR-10.5: All Firestore operations MUST be scoped to the authenticated user's document tree

### FR-11: Offline Session Handling

- FR-11.1: At workout completion, if Firebase is unreachable, the session summary (`sessions` document + `hr_stream` records) MUST be queued locally using Core Data or UserDefaults
- FR-11.2: The app MUST automatically detect when connectivity is restored and flush the local queue to Firestore
- FR-11.3: Live `hr_stream` writes during workout (every 5 sec) are best-effort — not queued offline
- FR-11.4: The UI MUST indicate to the user when a session was saved locally and is pending sync

---

## Non-Functional Requirements

### NFR-01: Performance
- HR coaching response latency MUST be < 2 seconds from HR reading to feedback delivery
- Firebase writes MUST NOT block coaching logic (async, fire-and-forget)
- Zone calculation MUST complete in < 10ms on device

### NFR-02: Platform Targets
- iOS 17+ (iPhone)
- watchOS 10+ (Apple Watch)

### NFR-03: Reliability
- App MUST handle Apple Watch disconnection gracefully — continue iPhone-side session, sync state when reconnected
- All user data stored under authenticated Firebase user ID

### NFR-04: Privacy & Security
- RHR and age data MUST never be sent to third parties
- All health data handling MUST comply with HealthKit privacy requirements
- Firebase Auth tokens MUST be managed per SECURITY-12
- Sensitive health data MUST be stored in Keychain, not UserDefaults (per SECURITY-01)
- All Firebase communication uses HTTPS/TLS (enforced by Firebase SDK)

### NFR-05: Visual Design
- Dark mode primary across all screens (black/dark backgrounds)

### NFR-06: Testability
- Zone calculator (ZoneCalculator.swift) MUST be covered by property-based tests (PBT-02, PBT-03)
- Coaching engine (CoachingEngine.swift) MUST be covered by property-based tests (PBT-02, PBT-03)
- PBT framework: **Swift Testing + swift-gen** or equivalent Swift PBT library (PBT-09)
- All PBT tests MUST support shrinking and seed-based reproducibility (PBT-07, PBT-08)

---

## Technical Architecture Summary

| Component | Technology |
|---|---|
| iPhone app | Swift + SwiftUI |
| Watch app | watchOS + WatchKit |
| Shared code | Local SPM package (`HeartRateCoachCore`) |
| Phone ↔ Watch | WatchConnectivity framework |
| HR data | HealthKit (`HKWorkoutSession`) |
| Database | Firebase Cloud Firestore (new project) |
| Auth | Firebase Auth (Sign in with Apple) |
| Voice feedback | AVSpeechSynthesizer (iPhone only) |
| Haptics | `WKInterfaceDevice.current().play()` (Watch) |
| Offline queue | Core Data or UserDefaults (session-level only) |
| Coaching logic | On-device (iPhone) — Firebase = storage only |

---

## Out of Scope (v1)

- Android / Google Fit support
- Custom workout builder
- AI-powered coaching recommendations
- Social features or leaderboards
- Subscription / paywall
- iPad layout
- Apple Health write-back (step count, calorie export)
- Watch face complications
- Watch speaker voice output

---

## Definition of Done (v1)

- [ ] User can complete onboarding and have HR zones calculated
- [ ] User can start any of the 3 workout programs from iPhone
- [ ] Apple Watch displays live HR and current zone during workout
- [ ] Coaching engine delivers correct voice + haptic feedback per zone
- [ ] Safety stop triggers correctly when HR > HRmax
- [ ] Session is saved to Firestore on completion (or queued offline if unreachable)
- [ ] Offline-queued sessions sync automatically when connectivity is restored
- [ ] Session history is viewable in app
- [ ] All 3 workout programs follow correct phase/timing/zone sequences
