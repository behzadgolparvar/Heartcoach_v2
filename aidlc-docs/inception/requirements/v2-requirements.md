# v2 Requirements — HeartCoach Redesign

**Cycle:** v2 (brownfield, native Swift/SwiftUI) · **Branch:** new_design_Sep_2026
**Functional source of truth:** `hr-coaching-app-full-spec.md`, `onboarding-form-spec.md` (this document consolidates them with the decisions from `v2-requirements-questions.md`; the specs remain authoritative for detailed tables/phrase pools).

---

## 1. Scope & Intent
Transform v1 (manual workout picker + 3 fixed programs) into a personalized HR-coaching program that **assigns** workouts from a rich profile and progression model, delivers a much richer real-time coaching experience, and captures clinical/research-grade data. iPhone + Apple Watch, native Swift. Healthy individuals only (no diagnosed-condition enrollment yet).

## 2. Key Decisions (from Q&A)
| # | Decision |
|---|---|
| Tech | Native Swift/SwiftUI — reuse v1 auth, HealthKit, Watch HR pipeline, Firestore |
| Assignment | **Full auto-assignment engine** is the headline feature (experience + goals + mentality + monthly progression) |
| Reminders | Local **push notifications** (no Twilio calls) |
| Health fields | **Collect & store all**, including future/clinical-only (future-only fields in an optional section) |
| Export | **Include** per-session CSV/XLSX to Firebase Storage (research) |
| Delivery | **Incremental phases**, each TestFlight-shippable; `main` stays on v1 |
| Security | Baseline **Full/blocking** |
| PBT | **Partial** — pure logic (zones, assignment, coaching) + serialization round-trips |

## 3. Functional Requirements

### FR-1 Onboarding (redesigned)
Consent-first, 7 sections in order: **Consent → Demographics/Health → Time & Scheduling → Mentality → Facility/Equipment → Goals → Device/Tech**.
- Demographics: age, gender, weight & height with **unit toggles (lbs/kg, cm/in) storing both**, auto **BMI**, RHR (guided from Apple Health, 40–100 warning), Max HR (auto `220−age`, optional manual), occupation activity, **fitness experience** (active), plus optional health-history (chronic conditions, HR meds incl. beta-blockers, Ozempic, smoking, joint issues — stored, mostly future-use).
- Scheduling: session length, frequency/week, preferred days, time of day, reminder method.
- Mentality: 3 single-selects (process↔outcome, habit↔goal, fixed↔variety) — drive assignment lean + coaching tone.
- Goals: multi-select (fast weight loss / routine / cardio fitness).
- Device: wearable, existing tracking app.
- Consent: 2 required checkboxes before any data collection.

### FR-2 HR Zones (Karvonen)
`HRmax = 220−age`; zones at 50/60/70/80/90% of HRR. **Identical to v1.** Biweekly RHR-recheck prompt. Optional manual Max HR override. (Flag: HR-affecting meds may warrant a zone-adjust note / physician-consult flag — capture, no auto-adjust yet.)

### FR-3 Workout Assignment Engine (headline)
Per full-spec §2: Beginner+weight-loss → progression-ratio HIIT:Continuous by month × mentality; Beginner+routine/cardio → Continuous (mentality-modulated); Intermediate/Advanced → both unlocked, daily lean by mentality/goal/time. Requires **progression tracking** (per-type session history, month buckets). Health/joint fields do **not** affect type assignment.

### FR-4 Training Protocols (redesigned; Fartlek removed)
- **Continuous**: 35 min, 5-min warm-up, 7 blocks, progressive %HRR (full-spec §3.1 table), never > Zone 4.
- **HIIT**: 35 min, 5-min warm-up + 15×(1 min work / 1 min walk), progressive %HRR with **6 true blocks** (§3.2 table). Rest phases: instruction only, no zone coaching, safety still active.
- `target_zone` timeline is deterministic (timer-driven).

### FR-5 Real-Time Coaching (richer)
Per full-spec §4. Priority: safety > end-of-phase (last 10 s) > escalation > standard zone > round/block-start. Off-zone check **every 15 s**; safety **every 5 s**. Severity tiers minor(<5 bpm)/major(≥5) × low/high + in-zone (rare) — **phrase pools** of 5–6 variants, no-phrase-3×-in-a-row rotation. Block-transition announcements + direction phrases (HIIT). "N rounds/blocks left" reminders. **Escalation** on sustained off-zone (HIIT 30 s / Continuous 60 s, resets on re-entry). **Pre-session briefing** (~1 min, mandatory first 4 sessions per type, skippable after). Voice-off → every message has on-screen text equivalent.

### FR-6 Session Scoring & Summary
Score = % time in target zone → tiers (Excellent/Great/Good/Fair/Needs work). Two outputs: spoken closing (tier-matched) + visual summary (%, tier, time-in-each-zone).

### FR-7 Reminders
Schedule-driven **local notifications**; auto-adjust when the user edits day/time preferences; content states today's scheduled session + duration.

### FR-8 Data & Export
Firestore schema per full-spec §5.1: `profile` / `physiology` / `hr_zones` / `settings`; `sessions` with `session_flag` (continuous | hiit | walk_fallback); `hr_stream` per-second incl. **`phrase_type` + `phrase_time`**. Per-session **CSV/XLSX export to Firebase Storage** (research; hidden from user).

### FR-9 Safety & Edge Cases (full-spec §6)
Sensor dropout (20 s → prompt, resume-in-place, data gap flagged, safety-unavailable warning); pause/resume with 15-min prompt (Continue/Finish/More time, max 3 snoozes, safety off while paused); cancel rule (≥20 min scored, <20 discarded); **elevated-starting-HR walk-fallback** protocol (logged as `walk_fallback`, excluded from progression stats). Safety stop (HR > HRmax) always active except during dropout/pause (user informed).

## 4. Non-Functional Requirements
- **Platform:** iOS 17+, watchOS 10+, native Swift/SwiftUI; logic local, Firebase = storage only.
- **Security (Baseline, blocking):** encryption in transit/at rest (Firebase); no secrets committed; **no PII/health data in logs**; Firestore rules restrict users to own data; consent gating.
- **Privacy:** consent screens; privacy policy to be drafted before wider release (medical fields collected) — flagged, not blocking healthy-only pilot.
- **Testability:** PBT (partial) on zone calc, assignment engine, coaching selection, serialization round-trips; unit tests for logic; device test for Watch/HealthKit.
- **Reliability:** offline-tolerant saves (v1 pattern), graceful data-gap handling.

## 5. Reuse vs New
**Reuse (v1):** Firebase Auth (email/pw), Apple Watch HR pipeline (WCSession, auto-start, HealthKit), Karvonen zone calc, voice/haptic infra, Firestore + security rules, session-manager/tick architecture, retry/onboarding-safety.
**New:** redesigned onboarding + expanded data model; assignment + progression engine; redefined Continuous/HIIT protocols (Fartlek removed); rich coaching (phrase pools, tiers, escalation, transitions, briefing); scoring; reminders (notifications); CSV/XLSX export; expanded safety/edge handling; consent.

## 6. Out of Scope (this cycle)
Twilio calls/SMS; Android; clinical/diagnosed-condition enrollment; equipment-recommendation logic (fields captured only); combined half/half workout type; auto zone-adjust from medications.
