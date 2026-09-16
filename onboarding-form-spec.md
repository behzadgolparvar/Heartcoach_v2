# User Onboarding Form — Specification for Developer

**App:** HR Coaching App
**Purpose:** Collect the data needed to (1) personalize HR training zones via the Karvonen formula, (2) schedule reminders, (3) tailor coaching tone/content, and (4) meet health-data consent requirements.

---

## 1. Demographics & Health Profile

| Field | Type | Options / Notes |
|---|---|---|
| Age | Number | Required. Used in Karvonen calc. |
| Gender | Single-select | Male / Female / Prefer not to say |
| Weight | Number + unit toggle | lbs or kg — user picks either; app auto-converts and stores both |
| Height | Number + unit toggle | cm or inches — same auto-convert logic |
| BMI | Auto-calculated | Derived from weight & height, not user-entered |
| Chronic conditions | Multi-select | T2DM, CVD, Hypertension, Other (free text), None |
| **Heart-rate-affecting medications** | Multi-select | **Beta-blockers**, other HR-affecting meds, None — *flag: critical for Karvonen accuracy, more so than weight-loss meds* |
| On Ozempic / anti-obesity therapy | Yes/No | |
| Smoking status | Single-select | Never / Former / Current |
| Joint/orthopedic issues | Multi-select | Knees, back, hips, ankles, Other, None — affects safe workout type recommendations |
| Resting HR | Number (optional) | If known/measured |
| Max HR | Number (optional) | If known/measured; otherwise app estimates via age-based formula |
| Job / occupation activity level | Single-select | Sedentary / Lightly active / Active / Very active |
| Fitness experience | Single-select | Beginner / Intermediate / Advanced |

---

## 2. Time & Scheduling

| Field | Type | Options / Notes |
|---|---|---|
| Available time per session | Number (minutes) | e.g., 30 min |
| Frequency per week | Number | e.g., 3x/week |
| Preferred workout days | Multi-select | Mon–Sun |
| Preferred time of day | Single-select | Morning / Afternoon / Evening |
| Reminder method | Single-select | Call / Text message |

---

## 3. Mentality / Motivation

| Field | Type | Options |
|---|---|---|
| Motivation driver | Single-select | "I enjoy the process/workout itself" vs. "I care most about seeing results" (process- vs. outcome-focused) |
| Response to missed workout | Single-select | "I feel like I broke a habit" vs. "I feel like I'm losing progress" (habit- vs. goal-driven) |
| Routine preference | Single-select | "I prefer a fixed routine" vs. "I prefer variety" |

*Note: these map to established exercise-psychology concepts (intrinsic vs. extrinsic motivation) and should inform coaching message tone, not just scheduling.*

---

## 4. Facility / Equipment

| Field | Type | Options |
|---|---|---|
| Available equipment/facility | Multi-select | Biking, Elliptical, Treadmill, Outdoor running, Other |
| Home equipment | Multi-select | Optional — for inconsistent gym access |
| Indoor vs. outdoor preference | Single-select | Indoor / Outdoor / No preference |

---

## 5. Goals

| Field | Type | Options |
|---|---|---|
| Goal(s) | Multi-select | 1) Fast weight loss 2) Doing exercise as routine 3) Improving cardiovascular fitness — user may pick one, two, or all three |

---

## 6. Device / Tech

*App is iPhone-only.*

| Field | Type | Options |
|---|---|---|
| Wearable device | Single-select | Apple Watch / None |
| Existing tracking app | Multi-select | Strava, Other, None |

---

## 7. Consent & Privacy

| Field | Type | Notes |
|---|---|---|
| Consent to health data collection & use | Required checkbox | Must be presented and accepted before any other data is collected |
| Consent to reminders (calls/texts) | Required checkbox | |

**Developer note:** Given the health data collected (T2DM, CVD, medications), a privacy policy covering data storage, use, and compliance (e.g., HIPAA considerations if applicable to your market) should be drafted and linked from this consent screen before launch.

---

## Implementation Notes

- **Units**: store both metric and imperial values internally; let the UI display whichever the user selected.
- **Karvonen inputs**: Age, Resting HR, Max HR (measured or estimated), and HR-affecting medication flags should all feed directly into the zone-calculation logic — medication status may require a manual zone adjustment or a flag for the user to consult a physician.
- **Order of screens**: Consent → Demographics/Health → Time & Scheduling → Mentality → Facility → Goals → Device — consent first, since health data collection follows it.
- **Platform**: iOS only — device integration should target Apple HealthKit / Apple Watch; no Android/Wear OS branching needed.
