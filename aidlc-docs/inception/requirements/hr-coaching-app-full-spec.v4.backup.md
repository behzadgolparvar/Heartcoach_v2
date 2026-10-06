# HR Coaching App — Full Development Specification

**Platform:** iPhone only
**Entry requirement:** Healthy individuals only — no patients with diagnosed conditions are enrolled in this program at this time.

---

## 1. Onboarding Form

### 1.1 Demographics & Health Profile

| Field | Type | Options / Notes |
|---|---|---|
| Age | Number | Required — used in Karvonen calc |
| Gender | Single-select | Male / Female / Prefer not to say |
| Weight | Number + unit toggle | lbs or kg — user picks either; app auto-converts and stores both |
| Height | Number + unit toggle | cm or inches — same auto-convert logic |
| BMI | Auto-calculated | Derived from weight & height |
| Chronic conditions | Multi-select | T2DM, CVD, Hypertension, Other (free text), None — **stored for future/clinical reference only, no current logic impact** |
| HR-affecting medications | Multi-select | Beta-blockers, other, None — **stored for future reference only** |
| On Ozempic / anti-obesity therapy | Yes/No | Stored for future reference only |
| Smoking status | Single-select | Never / Former / Current |
| Joint/orthopedic issues | Multi-select | Knees, back, hips, ankles, Other, None — **stored for future use: will drive equipment recommendations (e.g., elliptical over treadmill), not workout-type assignment** |
| Resting HR (RHR) | Number | Guided entry: obtain from Apple Health, morning value recommended. Normal range 40–100 bpm; outside this range triggers a confirm-value warning |
| Max HR (HRmax) | Auto-estimated | `220 − age` (minimal version) |
| Job / occupation activity level | Single-select | Sedentary / Lightly active / Active / Very active |
| Fitness experience | Single-select | Beginner / Intermediate / Advanced — **active, drives assignment logic** |

### 1.2 Time & Scheduling

| Field | Type | Notes |
|---|---|---|
| Available time per session | Number (minutes) | |
| Frequency per week | Number | e.g., 3x/week |
| Preferred workout days | Multi-select | Mon–Sun |
| Preferred time of day | Single-select | Morning / Afternoon / Evening |
| Reminder method | Single-select | Call / Text |

**Reminder behavior:** Reminders are driven by the user's schedule. If the user edits their day/time preferences, reminders automatically adjust — no separate reconfiguration step.

**Call reminder content:** A short automated message stating today's scheduled training and its duration (e.g., "Today you have a 35-minute HIIT session scheduled."). Flag for developer: automated calling requires a calling API (e.g., Twilio) with TTS — confirm this is worth building vs. a push-notification equivalent with the same content.

### 1.3 Mentality / Motivation

| Field | Options |
|---|---|
| Motivation driver | Process/way-focused vs. Outcome-focused |
| Response to missed workout | Habit-driven vs. Goal-driven |
| Routine preference | Fixed routine vs. Variety |

**Active use:** Drives workout-type recommendation/ratio (see Section 2) and coaching tone.

### 1.4 Facility / Equipment

| Field | Options |
|---|---|
| Available equipment/facility | Biking, Elliptical, Treadmill, Outdoor running, Other |
| Home equipment | Optional, free text/multi-select |
| Indoor vs. outdoor preference | Indoor / Outdoor / No preference |

### 1.5 Goals

| Field | Type | Options |
|---|---|---|
| Goal(s) | Multi-select | 1) Fast weight loss 2) Doing exercise as routine 3) Improving cardiovascular fitness — user may select one, two, or all three |

### 1.6 Device / Tech

| Field | Options |
|---|---|
| Wearable device | Apple Watch / None |
| Existing tracking app | Strava, Other, None |

### 1.7 Consent

| Field | Notes |
|---|---|
| Consent to health data collection & use | Required checkbox, shown before any data collection begins |
| Consent to reminders (calls/texts) | Required checkbox |

**Privacy policy note:** Not required at this stage since only healthy subjects are enrolled. If the program ever expands to include people with diagnosed conditions, this must be revisited.

---

## 2. Continuous / HIIT Assignment Logic

### 2.1 Entry Rule
Only healthy individuals are accepted into the program. Health condition/medication fields are collected for future reference only and do not affect assignment.

### 2.2 Base Assignment Logic

| Experience | Goal | Assignment |
|---|---|---|
| Beginner | Fast weight loss | Combination — alternating Continuous/HIIT, per progression table below |
| Beginner | Routine / Cardio fitness | Continuous only (build base first) |
| Intermediate / Advanced | Any goal | Both unlocked — daily recommendation driven by goal, time, and mentality |

### 2.3 Mentality Effect (Intermediate/Advanced)

| Mentality | Daily Recommendation Lean |
|---|---|
| Outcome-focused | Lean HIIT |
| Process/way-focused | Lean Continuous |
| Mixed/no strong lean | Balanced — driven by goal + time |

### 2.4 Beginner Progression (Fast Weight Loss Goal, 3 sessions/week)

Ratio = HIIT : Continuous

| Mentality | Months 1–2 | Months 3–4 | Months 5–6 |
|---|---|---|---|
| Outcome-focused | 1:2 | 1:1 | 2:1 (flipped — more HIIT than Continuous) |
| Mixed/no strong lean | 1:3 | 1:2 | 1:1 |
| Process/way-focused | 1:4 | 1:3 | 1:2 |

### 2.5 Beginner — Routine/Cardio Fitness Goal

| Mentality | Assignment |
|---|---|
| Outcome-focused | Mostly Continuous, with occasional HIIT worked in (~1 in 4 sessions) |
| Process/way-focused | Continuous only |
| Mixed/no strong lean | Continuous only |

### 2.6 Notes
- Joint/orthopedic issues: no impact on type assignment now or in the future — reserved for future equipment recommendations only.
- Combined exercise type (half Continuous/half HIIT) and periodic "trial" sessions: discussed and parked — not part of current spec.

---

## 3. Training Protocols

Both protocols run **35 minutes**, always beginning with a 5-minute warm-up.

### 3.1 Continuous — Structure

Progressive intensity, increasing every 5 minutes, never exceeding Zone 4.

| Block | Time | Zone | %HRR |
|---|---|---|---|
| 1 | 0–5 min | Zone 1 | 50–60% (fixed warm-up) |
| 2 | 5–10 min | Zone 2 | 60–70% |
| 3 | 10–15 min | Zone 2–3 | 65–75% |
| 4 | 15–20 min | Zone 3 | 70–80% |
| 5 | 20–25 min | Zone 3–4 | 75–85% (peak) |
| 6 | 25–30 min | Zone 3 | 70–80% (ease back) |
| 7 | 30–35 min | Zone 3–4 | 75–85% (finish) |

**Worked example (age 32, RHR 52):** HRmax = 188 bpm, HRR = 136 bpm → Block 1: 120–134 bpm, Block 2: 134–147 bpm, Block 5 peak: ~154–168 bpm.

**Engine behavior:** `target_zone` updates on a fixed 5-minute timer, no user input or branching required.

### 3.2 HIIT — Structure

5-minute warm-up, then 15 rounds of 1-minute work / 1-minute rest (30 minutes total), progressive intensity across rounds (not linear — builds, eases, rebuilds).

| Minute | Phase | Round | Work %HRR | Rest |
|---|---|---|---|---|
| 5–6 | Work 1 | 1 | 65–75% | — |
| 6–7 | Rest 1 | 1 | — | Walk, normal pace |
| 7–8 | Work 2 | 2 | 65–75% | — |
| 8–9 | Rest 2 | 2 | — | Walk, normal pace |
| 9–10 | Work 3 | 3 | 70–80% | — |
| 10–11 | Rest 3 | 3 | — | Walk, normal pace |
| 11–12 | Work 4 | 4 | 70–80% | — |
| 12–13 | Rest 4 | 4 | — | Walk, normal pace |
| 13–14 | Work 5 | 5 | 70–80% | — |
| 14–15 | Rest 5 | 5 | — | Walk, normal pace |
| 15–16 | Work 6 | 6 | 75–85% | — |
| 16–17 | Rest 6 | 6 | — | Walk, normal pace |
| 17–18 | Work 7 | 7 | 75–85% | — |
| 18–19 | Rest 7 | 7 | — | Walk, normal pace |
| 19–20 | Work 8 | 8 | 75–85% | — |
| 20–21 | Rest 8 | 8 | — | Walk, normal pace |
| 21–22 | Work 9 | 9 | 80–90% | — |
| 22–23 | Rest 9 | 9 | — | Walk, normal pace |
| 23–24 | Work 10 | 10 | 80–90% | — |
| 24–25 | Rest 10 | 10 | — | Walk, normal pace |
| 25–26 | Work 11 | 11 | 80–90% | — |
| 26–27 | Rest 11 | 11 | — | Walk, normal pace |
| 27–28 | Work 12 | 12 | 75–85% | — |
| 28–29 | Rest 12 | 12 | — | Walk, normal pace |
| 29–30 | Work 13 | 13 | 75–85% | — |
| 30–31 | Rest 13 | 13 | — | Walk, normal pace |
| 31–32 | Work 14 | 14 | 80–90% | — |
| 32–33 | Rest 14 | 14 | — | Walk, normal pace |
| 33–34 | Work 15 | 15 | 80–90% | — |
| 34–35 | Rest 15 | 15 | — | Walk, normal pace |

**HIIT "block" definition:** A new block = a change in intensity range (rounds 1–2, 3–5, 6–8, 9–11, 12–13, 14–15 = 6 true blocks), not every round.

**Rest phase rule:** No HR-based coaching or zone checks during rest — instruction only ("Take a walk, normal pace"). Safety layer remains active.

---

## 4. Real-Time Feedback System

### 4.1 Priority Hierarchy (highest to lowest)
1. **Safety stop** (HR > HRmax) — overrides everything, active continuously across the entire session including rest/pause/dropout windows
2. **End-of-phase message** (last 10 seconds of any block/round) — suppresses zone feedback during this window
3. **Escalation** (sustained off-zone) — deferred to start of next phase if it coincides with an end-of-phase window
4. **Standard zone feedback** (off-zone correction or in-zone confirmation)
5. **Round/block-start announcement**

### 4.2 Check Timing
- **Off-zone check:** every 15 seconds
- **In-zone confirmation:** rare/occasional, not on a fixed timer (not removed entirely — kept sparse to avoid feeling punitive or robotic)
- **No-repeat rule:** no phrase repeats 3 times in a row; each condition has a pool of 5–6 rotating variants

### 4.3 Off-Zone Severity Tiers
Based on bpm deviation from target:
- **Minor** (<5 bpm off)
- **Major** (5+ bpm off)
Each tier is direction-aware (too low vs. too high) — 4 buckets total: minor-low, minor-high, major-low, major-high.

### 4.4 Phrase Pools

**Minor-Low:**
"Pick it up just a touch." / "A little more effort — you've got it." / "Bump it up slightly." / "Just a notch higher." / "Give me a bit more here." / "Nudge the pace up a little."

**Major-Low:**
"Let's go, pick up the pace!" / "You're behind target — push harder." / "Time to speed up, come on!" / "Dig in — bring that effort up." / "Push! Get back on target." / "Let's pick it up, you can do more."

**Minor-High:**
"Ease off just a bit." / "Ease up slightly, you're right there." / "Back it off a touch." / "Slight pull-back — you're close." / "Just soften the effort a little." / "Take a hair off the pace."

**Major-High:**
"Whoa, slow it down!" / "Ease up — you're pushing too hard." / "Pull back the pace now." / "Dial it back a bit, you're over target." / "Take it down a notch." / "Slow down — bring that heart rate back."

**In-Zone (rare):**
"Right where you need to be — nice work!" / "Perfect zone, keep it right there." / "That's it, you're locked in." / "Great pace, stay with it." / "You're crushing this zone — keep going!" / "Nailing it — hold steady."

### 4.5 Block/Round Transitions (HIIT-specific)
At true block transitions (intensity range changes, not every round), fire both:
1. New target zone announcement
2. Direction phrase relative to previous block: "Stepping it up from here." / "Time to push a little harder than before." / "Easing back slightly from the last stretch." / "Bringing the intensity down a notch." / "Here we go — harder than last block." / "Backing off slightly, recover into this one."

(Continuous does not use direction phrases — its progression is already framed by the block structure itself.)

Grace period (suppress corrective zone feedback) applies only at true block transitions, not every round.

### 4.6 Rounds/Blocks-Left Reminders
Short, count-only — no performance commentary.

**HIIT:** "9 rounds to go." / "6 left — keep going." / "3 more rounds." / "Halfway there — 7 to go." / "Last one — finish strong."

**Continuous:** "4 blocks to go." / "Halfway done — 3 left." / "2 blocks remaining." / "One more after this." / "Final block coming up."

### 4.7 Escalation
Triggered by **sustained duration off-zone**, not cue count:
- **HIIT:** 30 seconds sustained off-zone
- **Continuous:** 60 seconds sustained off-zone
- Timer resets once back in zone (even briefly)
- Escalation phrases: "Still off target — let's fix that now." / "I need you to adjust — come on, get back in zone." / "You've been off pace a while — time to correct." / "Let's reset — get that heart rate back in range." / "Come on, focus up — back to target."

### 4.8 Pre-Session Briefing (1 minute, before warm-up begins)
- Occurs **before** the 35-minute training block (total session time = 1 min briefing + 35 min training)
- General, non-numeric language describing the shape of the session (e.g., "First 5 minutes you'll warm up, then... by the end...")
- No mention of goal/mentality context
- Rotates across sessions (varied scripts, not fixed)
- **Mandatory for the first 4 sessions of each workout type** (Continuous and HIIT tracked separately); skip-intro option available from session 5 onward of that type

Example — Continuous: "Today's a 35-minute Continuous session. First 5 minutes, we warm up easy. Then we'll build the intensity gradually. By the end, you'll be working at a strong, solid effort. Let's get moving."

Example — HIIT: "Today's a 35-minute HIIT session. We warm up for 5 minutes, then move into rounds of hard work and walking recovery. The effort builds as we go. Let's get after it."

### 4.9 Post-Session Score & Closing Message
- **Score basis:** % of total session time spent in target zone
- **Tiers:**

| % in target zone | Tier |
|---|---|
| 90–100% | Excellent |
| 75–89% | Great |
| 60–74% | Good |
| 40–59% | Fair |
| <40% | Needs work |

- **Two outputs from the same score:**
  - **Spoken closing message** (immediate, short, tier-matched)
  - **Written/visual summary** on the Summary screen (percentage, tier, time-in-each-zone breakdown)

---

## 5. Data & Backend

### 5.1 Firestore Structure

```
users (collection)
├── userId (document)
├── profile: { age, sex, weight }
├── physiology: { resting_hr, max_hr }
├── hr_zones: { zone1..zone5: {min, max} }
├── settings: { goal, preferred_workout }

users/{userId}/sessions (subcollection)
├── sessionId
├── date, type, duration_sec, avg_hr
├── time_in_zones: { zone1..zone5 }
├── session_flag: "continuous" | "hiit" | "walk_fallback"

users/{userId}/sessions/{sessionId}/hr_stream (subcollection)
├── recordId
├── timestamp, second, hr, zone, target_zone, phase
├── phrase_type   ← new: category of message spoken at/near this moment
├── phrase_time   ← new: exact time the phrase played
```

### 5.2 Excel/CSV Export
- At session end, flatten that session's `hr_stream` into a CSV/XLSX (one row per second)
- Include `phrase_type` and `phrase_time` columns — internal use only (product development/research), not shown to the client
- Store export in Firebase Storage, retrievable per user/session

### 5.3 HR Zone Calculation
```python
def calculate_hr_zones(age, rhr):
    hr_max = 220 - age
    hrr = hr_max - rhr
    zones = {
        "zone1": (rhr + 0.50*hrr, rhr + 0.60*hrr),
        "zone2": (rhr + 0.60*hrr, rhr + 0.70*hrr),
        "zone3": (rhr + 0.70*hrr, rhr + 0.80*hrr),
        "zone4": (rhr + 0.80*hrr, rhr + 0.90*hrr),
        "zone5": (rhr + 0.90*hrr, hr_max)
    }
    return zones, hr_max
```

**Recalculation cadence:** Biweekly RHR recheck prompt (in addition to any manual age/RHR update).

### 5.4 Architecture
- Logic runs **locally in Flutter**, not in Firebase — Firebase is storage only
- Apple Watch (HealthKit) → Flutter (buffer, safety check, coaching logic) → Firebase (storage) → Voice (Flutter TTS) + Haptic feedback
- HR arrives every 5 seconds; safety check every 5 sec; coaching evaluation every 15 sec (revised from initial 10 sec)

### 5.5 Authentication & Security
- **Auth method:** Email/password
- **Firestore security rules:** required — users may only read/write their own data

---

## 6. Safety & Edge Cases

### 6.1 Sensor Dropout
- No HR reading for **20 seconds** = dropout detected
- Prompt user to fix connection
- On reconnect: session **continues from where it was** — no restart
- Data gap in `hr_stream` for the dropout window (flag for developer: handle gracefully in graphs/analysis, not as an error)
- Safety monitoring is unavailable during dropout — user should be made aware the app cannot protect them while disconnected

### 6.2 Pause / Resume
- User-initiated pause; timer holds exactly where paused (no time counted while paused)
- At **15 minutes paused**, prompt with three options:
  1. **Continue** — resumes at exact phase/second, grace period applies
  2. **Finish** — ends session early, scores based on data recorded so far
  3. **I need more time** — snoozes prompt for another 10 minutes; resume is always available regardless
- **Max 3 snoozes** — after that, must Continue or Finish
- Safety layer inactive while paused (same rationale as dropout)

### 6.3 Cancel / Incomplete Sessions
- **≥20 minutes elapsed:** session scored based on data collected
- **<20 minutes elapsed:** discarded as incomplete/junk data

### 6.4 Elevated Starting HR
| Step | Condition | Action |
|---|---|---|
| 1 | HR elevated at start | 5-minute walk, safety-check only (no zone coaching) |
| 2 | HR settles by end of step 1 | Proceed into normal planned session (Continuous or HIIT) |
| 3 | HR still elevated | Notify user; switch to 1 min fast walk / 1 min slow walk intervals |
| 4 | Remainder of session | Continues as walking intervals only — no Continuous/HIIT that day, safety-check only |

This fallback session is **logged and scored** (≥20 min rule applies) but **flagged distinctly** (e.g., `session_flag: "walk_fallback"`) — excluded from normal Continuous/HIIT history stats and progression tracking, but retained for clinical/research review.

### 6.5 Voice-Off / Silent Mode
All spoken messages must have an on-screen text/visual equivalent as fallback.

---

## 7. Open Items for Developer

These are implementation details flagged during design but not fully specified — resolve during build:

1. **Call reminders** — automated calling requires a calling API (e.g., Twilio) with TTS; confirm feasibility/cost vs. push-notification equivalent with the same content.
2. **Firestore security rules** — must be written to ensure users can only access their own data.
3. **OS permissions** — HealthKit background access and push notification permissions need proper setup/request flows; not a design decision, just don't miss it.
4. **Data gap handling** — ensure graphing/analysis tools handle missing seconds (from dropouts) gracefully rather than erroring.
5. **Privacy policy** — not required at this stage (healthy-subjects-only program), but must be revisited if the program ever expands to include diagnosed conditions.
