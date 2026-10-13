# Integration & On-Device Test Instructions — HeartCoach v5

These require a real iPhone + paired Apple Watch (HR sensor, HealthKit, background audio). Run after the simulator build passes.

## Setup
- Sign in; complete v5 onboarding (dual experience Q1/Q2; try an Ozempic=Yes path → auto-Beginner popup).
- Grant HealthKit + notification permissions when prompted.

## End-to-end per stage
For **Foundation**, then (after advancing) **Level Up**, then **Shape**:
1. Start the assigned session from Home ("Today: …"). Confirm the Watch wakes into a workout and HR streams to the iPhone within a few seconds.
2. **Coaching:** verify zone feedback cadence (15s standard; **Shape HIIT runs = 2 checks/50s**), severity phrasing, escalation, no-3×-repeat, block/round transitions.
3. **Exercises (Level Up/Shape):** intro cue + rep target + "switch legs" on unilateral; (backlog B: per-rep count once implemented).
4. **Cooldown:** end of training → 30s buffer (Continuous) → **"Ready to stretch?" gate** (tap Begin) → 6-step stretch with voice cues.
5. **Scoring:** closing tier spoken + visual summary (% in target, tier, zones); confirm cooldown excluded from the score.
6. **Save → progression advances** (session N→N+1); confirm the Home card updates.

## Stage transitions
- Complete a stage (test harness or many sessions) → "Unlock Level Up / Shape" → unlock questions (injury pre-filled from onboarding; Shape equipment/focus) → next stage assigns correctly, counter resets to 0, classification unchanged.
- Shape complete → "Maintain coming soon".

## Progression / relapse / minimum
- Simulate a gap (device clock or seeded dates) → relapse push-back applies once, positive message shown (Q5=B: can cross sub-phase; >1mo → session 0).
- "Do your 15-min minimum" → timed 8/7 walk → relapse clock resets, counter unchanged.

## Phase 6 systems
- **Milestone:** force due → check-in card; log weight → auto RHR recorded; miss 2 days → **Start blocked** until logged.
- **Reminders:** confirm local notifications fire for session/milestone/weight/nudge; edit schedule → they reschedule; **no HR/score/weight in payload text**.
- **Export:** after save, confirm a CSV appears at `users/{uid}/exports/<id>.csv` in Firebase Storage (requires rules published).
- **PDF:** "View my plan" → share sheet with a readable per-stage 60-session plan.

## Safety / edge (backlog A — verify as implemented)
- Sensor dropout 20s → prompt + resume; pause 15-min prompt + snoozes; elevated-HR → `walk_fallback` (excluded from progression); emergency stop on HR>max in every phase except dropout/pause.

## Watch install gotcha
If the Watch app stalls at 75%, install directly with `xcrun devicectl device install app` (see build-instructions).
