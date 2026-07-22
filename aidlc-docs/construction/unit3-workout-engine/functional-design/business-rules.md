# Business Rules — Unit 3: iPhone Workout Engine

---

## Workout Selection Rules

### BR-U3-01: Preferred Workout as Default
- **Rule**: The pre-start screen always defaults to the user's `profile.preferredWorkout`.
- **Rule**: The user can change the selection on the pre-start screen before tapping "Begin."
- **Rule**: Changing the selection on the pre-start screen does NOT update `preferredWorkout` in the profile — it is a one-time override for that session only.

---

## Coaching Engine Rules

### BR-U3-02: Layer Priority
- **Rule**: Layer 1 (Safety) is always evaluated first on every 5-second tick.
- **Rule**: If Layer 1 fires, Layers 2 and 3 are NOT evaluated for that tick.
- **Rule**: If Layer 2 fires, Layer 3 is NOT evaluated for that tick.
- **Rule**: Layers are mutually exclusive per tick — only one layer can produce output.

### BR-U3-03: Layer 1 — No HR Signal
- **Rule**: If `hr == 0`, a "No heart rate signal" safety banner is shown on the workout screen.
- **Rule**: No haptic or voice is triggered for a missing HR signal (avoid alarming the user unnecessarily).
- **Rule**: Layer 1 signal-loss message fires on every tick while HR remains 0.

### BR-U3-04: Layer 1 — Emergency Stop
- **Rule**: If `hr > HRmax` (> `220 - age`), emergency stop is triggered immediately.
- **Rule**: Emergency stop cannot be overridden — the workout must end.
- **Rule**: After emergency stop, a partial session is assembled and the summary screen is shown.

### BR-U3-05: Layer 2 — Grace Period
- **Rule**: Layer 2 is suppressed during the first 10 seconds of any HIIT or Fartlek exercise phase (`sequencer.isGracePeriodActive == true`).
- **Rule**: Grace period does NOT apply to Continuous training or to recovery phases.
- **Rule**: Layer 1 (Safety) is NEVER suppressed by the grace period.

### BR-U3-06: Layer 2 — Anti-Spam
- **Rule**: Layer 2 may fire at most once every 20 seconds.
- **Rule**: The 20-second anti-spam timer resets when a new phase begins.
- **Rule**: Anti-spam applies across both "Speed up" and "Slow down" messages — they share the same timer.

### BR-U3-07: Layer 2 — Recovery Phases
- **Rule**: Layer 2 does NOT fire during recovery phases (`phase.targetZone == nil`).
- **Rule**: During recovery, the zone ring shows the current HR in neutral (grey) with the phase instruction.

### BR-U3-08: Layer 3 — Positive Feedback Trigger
- **Rule**: Layer 3 fires after 30 consecutive seconds in the target zone.
- **Rule**: "Consecutive" is measured from the last time the user was NOT in the target zone (or the phase started).
- **Rule**: If the user leaves the target zone even briefly, `consecutiveInZoneSeconds` resets to 0.
- **Rule**: Layer 3 fires at most once per 30 seconds (it resets after firing).
- **Rule**: Layer 3 does NOT fire during recovery phases or when no target zone exists.

### BR-U3-09: HR Smoothing
- **Rule**: `hrSmooth` = integer mean of the last 2 HR readings.
- **Rule**: If only 1 reading is in the buffer (very start of workout), `hrSmooth` = that single reading.
- **Rule**: Layer 2 zone evaluation uses `hrSmooth`, NOT the raw HR reading.

---

## Voice Coaching Rules

### BR-U3-10: Voice Always Active
- **Rule**: Voice coaching fires for all Layer 2 and Layer 3 messages via `AVSpeechSynthesizer`.
- **Rule**: Voice can be muted by the user via a toggle in Settings. When muted, text appears on screen and haptics fire, but speech is suppressed.
- **Rule**: Layer 1 emergency messages are ALWAYS spoken, regardless of mute setting.

### BR-U3-11: Voice Interruption
- **Rule**: A new coaching message interrupts any currently-speaking message (`AVSpeechSynthesizer.stopSpeaking(at: .immediate)` before speaking).
- **Rule**: Layer 1 messages always interrupt regardless of what is currently speaking.

---

## Pause / Resume Rules

### BR-U3-12: Full Pause Semantics
- **Rule**: Pause freezes the phase timer, suspends the 5-second tick loop, and sends `.workoutStopped` to Watch.
- **Rule**: HR records are NOT collected during a pause — there will be gaps in `hrStream`.
- **Rule**: `elapsedSeconds` does NOT increment while paused.
- **Rule**: `consecutiveInZoneSeconds` resets to 0 when pausing (in-zone streak is broken).

### BR-U3-13: Resume Semantics
- **Rule**: Resume restarts the tick loop and sends `.workoutStarted` to Watch.
- **Rule**: The grace period is NOT reset on resume — if the user pauses and resumes mid-phase, grace period is already elapsed.
- **Rule**: Anti-spam timer (`lastLayer2MessageAt`) is reset on resume so a cue fires promptly after resuming.

---

## Session Integrity Rules

### BR-U3-14: avgHR Calculation
- **Rule**: `avgHR` = simple integer mean of all HR readings in `hrStream`.
- **Rule**: HR records from paused intervals are not in `hrStream` (full pause) — `avgHR` reflects only active exercise time.
- **Rule**: If `hrStream` is empty, `avgHR = 0`.

### BR-U3-15: timeInZones Calculation
- **Rule**: Each `HRRecord` contributes exactly 5 seconds to its `currentZone` total.
- **Rule**: Zone 0 (below zones) and Zone 6 (above HRmax) do NOT contribute to `timeInZones`.
- **Rule**: Recovery phase records contribute to `currentZone` time (the user's HR still falls in a zone during recovery).

### BR-U3-16: Session Save
- **Rule**: The session is saved ONLY when the user taps "Done" on the summary screen — not automatically at workout end.
- **Rule**: If the user closes the app on the summary screen without tapping "Done", the session is lost (acceptable for v1).
- **Rule**: Save attempts Firestore first; if unreachable, enqueues to `CoreDataOfflineQueue`.

---

## History Rules

### BR-U3-17: History Load Limit
- **Rule**: `HistoryView` loads up to 50 most recent sessions from Firestore.
- **Rule**: Sessions are sorted by `date` descending (most recent first).

---

## Decision Log

| Decision | Answer | Rationale |
|---|---|---|
| Workout selection | Pre-start screen (Q1 — A) | Preferred workout as default; one-tap override |
| Recovery phase UI | Show HR + neutral ring (Q2 — A) | HR drop during recovery is useful feedback |
| Voice trigger | Always (Q3 — A) | AirPods are primary use case; mute toggle for others |
| Pause behaviour | Full pause (Q4 — A) | Accurate avgHR; correct HealthKit semantics |
| Post-workout summary | Detailed (Q5 — B) | Zone breakdown is the most motivating moment |
