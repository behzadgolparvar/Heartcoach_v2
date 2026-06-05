# Heart Rate Coaching App — AI-DLC Project Brief

> **How to use this file with Claude Code + AI-DLC:**
> 1. Install AI-DLC rules in your project (see https://github.com/awslabs/aidlc-workflows#claude-code)
> 2. Place this file as `CLAUDE.md` in your project root
> 3. Start Claude Code and say: **"Using AI-DLC, build this heart rate coaching app as defined in CLAUDE.md"**

---

## 1. Project Overview

A native iOS + watchOS heart rate coaching app that guides users through structured workouts in real time using heart rate zone feedback, voice cues, and haptic feedback on the Apple Watch.

**Core value proposition:** The app reads live heart rate from Apple Watch, calculates personalized HR zones using the Karvonen formula, and coaches the user second-by-second through structured training programs — telling them to speed up, slow down, or stay the course.

---

## 2. Tech Stack (Final Decisions)

| Layer | Technology | Reason |
|---|---|---|
| iPhone app | Swift + SwiftUI | Native iOS, HealthKit integration |
| Watch app | watchOS + WatchKit | Native haptics, HR sensor, always-on display |
| Phone ↔ Watch communication | WatchConnectivity framework | Apple's native phone/watch bridge |
| Heart rate data | HealthKit (HKWorkoutSession) | Real-time HR from watch sensor |
| Database | Firebase Cloud Firestore | Structured session/HR storage |
| Auth | Firebase Auth (Sign in with Apple) | Privacy-first, Apple ecosystem |
| Voice feedback | AVSpeechSynthesizer (iOS TTS) | Native, no dependency |
| Haptic feedback | WKInterfaceDevice.current().play() | Native watchOS haptics |
| Logic layer | On-device (iPhone + Watch) | Real-time decisions; Firebase = storage only |

> **Important architecture decision:** All coaching logic runs on-device. Firebase is used exclusively for persistent storage of session history and user profile. No coaching decisions are made server-side.

---

## 3. User Profile & Physiological Engine

### 3.1 User Profile Data

```
age: Int                    // Required — used for HRmax calculation
sex: String?                // Optional ("male" / "female" / "other")
weight: Double?             // Optional (kg)
resting_hr: Int             // Required — entered manually by user
```

### 3.2 RHR Input Guidance (shown in onboarding UI)

- User is guided to retrieve RHR from Apple Health (morning resting value recommended)
- Accepted range: **40–100 bpm**
- Outside this range → show warning: *"This value is outside the typical range. Please confirm it is correct."*

### 3.3 HRmax Calculation

```
HRmax = 220 - age
```

### 3.4 HR Zone Calculation — Karvonen Formula

```
HRR = HRmax - RHR

zone1 = (RHR + 0.50 * HRR,  RHR + 0.60 * HRR)   // 50–60%
zone2 = (RHR + 0.60 * HRR,  RHR + 0.70 * HRR)   // 60–70%
zone3 = (RHR + 0.70 * HRR,  RHR + 0.80 * HRR)   // 70–80%
zone4 = (RHR + 0.80 * HRR,  RHR + 0.90 * HRR)   // 80–90%
zone5 = (RHR + 0.90 * HRR,  HRmax)               // 90–100%
```

**Recalculate zones whenever:** age or resting_hr is updated.

### 3.5 Zone Labels

| Zone | Name | Intensity |
|---|---|---|
| Zone 1 | Recovery | Very easy |
| Zone 2 | Easy / Fat burn | Easy |
| Zone 3 | Aerobic | Moderate |
| Zone 4 | Threshold | Hard |
| Zone 5 | Max effort | Maximum |

---

## 4. App Settings

```
goal: "fat_burn" | "endurance"
preferred_workout: "continuous" | "hiit" | "fartlek"
```

---

## 5. Workout Programs (Hardcoded in App — v1)

All three programs have total duration of **35 minutes**.

---

### 5.1 Continuous Training

**Structure overview:** Steady progressive effort through 5 cycles.

#### Warm-up (5 min)
| Duration | Target Zone |
|---|---|
| 2 min | Zone 1 |
| 3 min | Zone 2 |

#### Training Phase (30 min) — 5 cycles
Each cycle:
- **5 min running** → target zone (see below)
- **1 min walking** → recovery (no HR enforcement, instruction: *"Walk it out / keep walking"*)

| Cycle | Target Zone |
|---|---|
| 1 | Zone 2 |
| 2 | Zone 3 |
| 3 | Zone 3 |
| 4 | Zone 3 |
| 5 | Zone 4 |

#### Cool-down (Optional)
- 2–5 min walking
- ~5 min guided stretching prompts

---

### 5.2 HIIT Training

**Structure overview:** 15 short high-intensity cycles with enforced recovery.

#### Warm-up (5 min)
| Duration | Target Zone |
|---|---|
| 2 min | Zone 1 |
| 3 min | Zone 2 |

#### Training Phase (30 min) — 15 cycles
Each cycle:
- **1 min HIGH intensity** → target zone (see below)
- **1 min RECOVERY walking** → target Zone 1–2 (not enforced, instruction: *"Walk it out / don't stop"*)

| Cycles | Target Zone (HIGH phase) |
|---|---|
| 1–3 | Zone 3 |
| 4–12 | Zone 4 |
| 13–15 | Zone 5 (optional / advanced) |

#### Special Rules
- **First 10 seconds of each interval:** no HR feedback (transition grace period)
- **Safety during recovery:** if HR is very high → cue: *"Slow your walk"*

#### Cool-down (Optional)
- 2–5 min walking
- ~5 min guided stretching prompts

---

### 5.3 Fartlek Training (Structured)

**Structure overview:** 15 varied 2-minute segments with embedded recovery in Zone 2.

#### Warm-up (5 min)
| Duration | Target Zone |
|---|---|
| 2 min | Zone 1 |
| 3 min | Zone 2 |

#### Training Phase (30 min) — 15 × 2 min segments

Pre-defined zone sequence (in order):

```
2 – 3 – 2 – 3 – 4 – 2 – 3 – 4 – 3 – 4 – 3 – 4 – 2 – 3 – 5
```

| Zone | Coaching Style |
|---|---|
| Zone 2 | *"Easy pace / find your rhythm"* |
| Zone 3 | *"Moderate effort / change pace"* |
| Zone 4 | *"Push it / hard effort"* |
| Zone 5 | *"Max effort / give everything"* (final segment, optional) |

#### Special Rules
- **First 10 seconds of each segment:** no HR feedback (transition grace period)
- No fixed recovery phase — recovery is embedded in Zone 2 segments
- Coaching style: flexible / natural cues (*"Change pace"*, *"Find rhythm"*)

#### Cool-down (Optional)
- 2–5 min walking
- ~5 min guided stretching prompts

---

## 6. Real-Time Coaching Engine

### 6.1 Input
- HR data arrives every **5 seconds** from Apple Watch via HKWorkoutSession

### 6.2 Three-Layer Logic (runs on-device)

#### Layer 1 — Safety (highest priority, runs every 5 sec)
```
IF current_HR > HRmax:
    STOP workout immediately
    Voice: "Your heart rate is above your estimated maximum. Stop exercising and check your condition."
    Haptic: strong repeated vibration
    Save emergency event to Firebase
```

#### Layer 2 — Zone Coaching (runs every 10 sec)

**Step 1: Smooth HR**
```
HR_smooth = average(last 2–3 HR readings)
```
Prevents noisy feedback from single-sample spikes.

**Step 2: Zone evaluation**
```
IF HR_smooth < target_zone_min:
    feedback = "Speed up"
    haptic = short vibration

IF HR_smooth > target_zone_max:
    feedback = "Slow down"
    haptic = long vibration

IF HR_smooth within target zone:
    no correction
```

**Step 3: Anti-spam rule**
```
Do NOT repeat the same message within 20 seconds
```

#### Layer 3 — Positive Feedback (condition-based, not timer-based)
```
IF user stays continuously in target zone for 30 sec:
    feedback = "Good job, keep going"
    haptic = double tap
```

### 6.3 Transition Grace Period
- For HIIT and Fartlek: **first 10 seconds** of each new phase → no coaching feedback
- Safety layer (Layer 1) remains active during grace period

### 6.4 Coaching Message Examples

| Situation | Voice Cue |
|---|---|
| HR below zone | *"Speed up"* |
| HR above zone | *"Slow down"* |
| HR in zone for 30s | *"Good job, keep going"* |
| Recovery phase | *"Walk it out / keep walking"* |
| HR very high during recovery | *"Slow your walk"* |
| HR above HRmax | *"Your heart rate is above your estimated maximum. Stop exercising and check your condition."* |
| Phase transition | *"Zone [X] — [label]. [coaching cue]"* |

### 6.5 Haptic Mapping

| Event | Haptic Pattern |
|---|---|
| Speed up | Short vibration |
| Slow down | Long vibration |
| Good job | Double tap |
| Emergency stop | Strong repeated vibration |

---

## 7. Firebase Database Schema

### 7.1 Collection: `users`

```
users/{userId}
  ├── profile
  │     ├── age: Number
  │     ├── sex: String (optional)
  │     └── weight: Number (optional)
  │
  ├── physiology
  │     ├── resting_hr: Number
  │     └── max_hr: Number
  │
  ├── hr_zones
  │     ├── zone1: { min: Number, max: Number }
  │     ├── zone2: { min: Number, max: Number }
  │     ├── zone3: { min: Number, max: Number }
  │     ├── zone4: { min: Number, max: Number }
  │     └── zone5: { min: Number, max: Number }
  │
  └── settings
        ├── goal: String           // "fat_burn" | "endurance"
        └── preferred_workout: String  // "continuous" | "hiit" | "fartlek"
```

### 7.2 Subcollection: `sessions`

```
users/{userId}/sessions/{sessionId}
  ├── date: Timestamp
  ├── type: String               // "continuous" | "hiit" | "fartlek"
  ├── duration_sec: Number
  ├── avg_hr: Number
  └── time_in_zones
        ├── zone1: Number        // seconds spent in zone
        ├── zone2: Number
        ├── zone3: Number
        ├── zone4: Number
        └── zone5: Number
```

### 7.3 Subcollection: `hr_stream` (time-series, long format)

```
users/{userId}/sessions/{sessionId}/hr_stream/{recordId}
  ├── timestamp: Timestamp
  ├── second: Number
  ├── hr: Number
  ├── zone: Number               // 1–5 (current zone user is in)
  ├── target_zone: Number        // 1–5 (zone the program requires)
  ├── phase: String              // "warmup" | "exercise" | "recovery" | "cooldown"
  └── coaching: String           // coaching message at this moment
```

**Write frequency:** Every 5 seconds during active workout.

**Session ID format:** Auto-generated by Firestore, or `session_YYYY_MM_DD_NNN`.

**Offline handling:** If Firebase is unreachable at session end, the completed session summary (`sessions` document + `hr_stream` records) MUST be queued locally (Core Data or UserDefaults) and synced to Firestore automatically when connectivity is restored. The `hr_stream` write frequency remains every 5 seconds during active workout — only the final session save is queued offline.

---

## 8. iPhone App — Screen Structure

| Screen | Purpose |
|---|---|
| Onboarding | Collect age, RHR, goal, preferred workout |
| Home | Select workout type, view last session summary |
| Workout Active | Live HR display, current zone, phase timer, coaching messages |
| Session Summary | Post-workout stats: time in zones, avg HR, duration |
| History | List of past sessions |
| Settings | Edit profile, RHR, goal, preferred workout |

---

## 9. Apple Watch App — Screen Structure

| Screen | Purpose |
|---|---|
| Workout Active | Live HR, current zone, target zone, phase indicator |
| Coaching overlay | Zone transition announcement |
| Emergency stop | Full-screen warning if HR > HRmax |

The watch app mirrors the active workout state from the iPhone via WatchConnectivity. HR data flows: **Watch sensor → WKWorkoutSession → WatchConnectivity → iPhone logic engine → Firebase**.

---

## 10. WatchConnectivity Data Flow

```
Watch (HR sensor)
  │
  ▼ HKWorkoutSession (real-time HR)
  │
  ▼ WatchConnectivity (sendMessage every 5 sec)
  │
  ▼ iPhone (CoachingEngine.swift)
  │     ├── Safety check
  │     ├── Zone evaluation
  │     ├── Voice feedback (AVSpeechSynthesizer)
  │     └── Firebase write (hr_stream record)
  │
  ▼ WatchConnectivity (reply: coaching command)
  │
  ▼ Watch (haptic feedback via WKInterfaceDevice)
```

---

## 11. Project File Structure (Target)

```
HeartRateCoach/
├── HeartRateCoach/                  # iPhone app target
│   ├── App/
│   │   └── HeartRateCoachApp.swift
│   ├── Models/
│   │   ├── UserProfile.swift
│   │   ├── HRZones.swift
│   │   ├── WorkoutProgram.swift     // Continuous, HIIT, Fartlek definitions
│   │   └── Session.swift
│   ├── Engine/
│   │   ├── ZoneCalculator.swift    // Karvonen formula
│   │   ├── CoachingEngine.swift    // Core coaching logic (all 3 layers)
│   │   └── SafetyMonitor.swift
│   ├── Services/
│   │   ├── FirebaseService.swift   // Firestore read/write
│   │   ├── HealthKitService.swift
│   │   └── WatchBridge.swift       // WatchConnectivity
│   ├── Views/
│   │   ├── Onboarding/
│   │   ├── Home/
│   │   ├── Workout/
│   │   ├── Summary/
│   │   └── Settings/
│   └── Resources/
│
├── HeartRateCoachWatch/             # watchOS app target
│   ├── App/
│   │   └── WatchApp.swift
│   ├── Views/
│   │   ├── WorkoutView.swift
│   │   └── EmergencyView.swift
│   ├── Services/
│   │   ├── WatchSessionManager.swift
│   │   └── HapticManager.swift
│   └── WorkoutManager.swift         // HKWorkoutSession on watch
│
├── Shared/                          // Code shared between targets
│   ├── Models/
│   └── Constants/
│
├── HeartRateCoachTests/
├── HeartRateCoachUITests/
└── GoogleService-Info.plist         // Firebase config (excluded from git)
```

---

## 12. Key Dependencies

| Dependency | Purpose | Integration |
|---|---|---|
| Firebase iOS SDK | Firestore + Auth | Swift Package Manager |
| HealthKit | HR data from watch | Native Apple framework |
| WatchConnectivity | Phone ↔ watch bridge | Native Apple framework |
| AVFoundation | TTS voice feedback | Native Apple framework |
| WatchKit | Haptics on watch | Native Apple framework |

---

## 13. Out of Scope for v1

- Android / Google Fit support
- Custom workout builder (programs are hardcoded)
- AI-powered coaching recommendations
- Social features or leaderboards
- Subscription / paywall
- iPad layout
- Apple Health write-back (step count, calorie export)
- ~~Offline Firebase sync handling~~ *(moved to in-scope — see Section 7 note)*

---

## 14. Non-Functional Requirements

- HR coaching response latency: < 2 seconds from HR reading to feedback
- Firebase write must not block coaching logic (async, fire-and-forget)
- App must handle watch disconnection gracefully (continue session, sync when reconnected)
- All user data stored under authenticated Firebase user ID
- RHR and age data never sent to third parties
- App targets iOS 17+ and watchOS 10+

---

## 15. Definition of Done (v1)

- [ ] User can complete onboarding and have HR zones calculated
- [ ] User can start any of the 3 workout programs from iPhone
- [ ] Apple Watch displays live HR and current zone during workout
- [ ] Coaching engine delivers correct voice + haptic feedback per zone
- [ ] Safety stop triggers correctly when HR > HRmax
- [ ] Session is saved to Firestore on completion
- [ ] Session history is viewable in app
- [ ] All 3 workout programs follow correct phase/timing/zone sequences
