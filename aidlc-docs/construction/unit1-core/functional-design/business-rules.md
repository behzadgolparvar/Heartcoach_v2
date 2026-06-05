# Business Rules — Unit 1: HeartRateCoachCore

---

## BR-01: Age Input Validation
- **Rule**: Age must be an integer between 15 and 100 (inclusive)
- **Rationale**: HRmax = 220 - age; values outside this range produce physiologically nonsensical zone boundaries
- **On violation**: Reject input; do not calculate zones

## BR-02: Resting HR Input Validation
- **Rule**: Resting HR must be an integer between 40 and 100 (inclusive)
- **Warning range**: Values outside 40–100 trigger a UI warning but do not block the user
- **Hard reject**: Values ≤ 0 or > 220 are rejected entirely
- **Rationale**: RHR below 40 is extremely rare (elite athletes only); above 100 indicates tachycardia

## BR-03: Zone Boundary Rounding
- **Rule**: All floating-point zone boundary values from the Karvonen formula are rounded up (ceiling) to the nearest integer
- **Rationale**: Makes zones slightly narrower — user must work slightly harder to be classified inside a zone
- **Exception**: `zone5.max = HRmax` is already an integer; no rounding applied

## BR-04: Zone Boundary Continuity
- **Rule**: Each zone's `min` must equal the previous zone's `max`
- **Ensures**: No gaps between zones; every HR value belongs to exactly one zone (or is below Zone 1 / above Zone 5)

## BR-05: Zone Classification at Boundary
- **Rule**: When HR exactly equals a zone boundary value, the reading is classified in the **lower zone**
- **Implementation**: Use strict less-than (`<`) for upper boundary comparisons: `hr < zone.max`
- **Example**: If zone2.max = 153 and HR = 153 → Zone 2

## BR-06: HR Below All Zones
- **Rule**: If HR < zone1.min, the reading is classified as zone 0 (below zones)
- **Coaching implication**: Zone 0 is treated as "below target" for any active target zone

## BR-07: HR Above HRmax
- **Rule**: If HR > zone5.max (i.e. HR > HRmax), the reading is classified as zone 6 (above maximum)
- **Safety implication**: Zone 6 immediately triggers Layer 1 emergency stop — handled by CoachingEngine (Unit 3)

## BR-08: HR Smoothing Buffer
- **Rule**: The smoothing buffer holds exactly the last 2 HR readings
- **Rule**: When fewer than 2 readings exist (start of workout), use all available readings
- **Rule**: `hrSmooth = integer mean of buffer contents`

## BR-09: Grace Period Applicability
- **Rule**: Grace period (10-second coaching suppression) applies ONLY to:
  - HIIT training — all exercise phases
  - Fartlek training — all 15 workout segments
- **Rule**: Grace period does NOT apply to:
  - Continuous training (any phase)
  - Warm-up phases (any program)
  - Recovery phases (any program)
- **Rule**: Layer 1 (safety) is NEVER suppressed by the grace period

## BR-10: Phase Sequencer Termination
- **Rule**: When the last phase in the sequence elapses, the sequencer emits `.mainWorkoutComplete` and stops advancing
- **Rule**: Cool-down is NOT automatically appended — it requires explicit user opt-in

## BR-11: Session avg_hr
- **Rule**: `avgHR = sum of all HR readings ÷ count of readings` (simple integer mean)
- **Rule**: If no HR readings exist (session ended immediately), `avgHR = 0`

## BR-12: Time-in-Zones Accounting
- **Rule**: Each HR record contributes exactly 5 seconds to its zone's total
- **Rule**: Recovery phase readings (where `targetZone == nil`) still contribute to `currentZone` time-in-zones
- **Rule**: Zone 0 and Zone 6 readings do NOT contribute to the 1–5 zone totals

## BR-13: WorkoutProgram Phase Integrity
- **Rule**: The total duration of all phases in a `WorkoutProgram` must equal 2100 seconds (35 minutes)
- **Rule**: This is verified at compile time via unit tests — not enforced at runtime

## BR-14: Zones Recalculation Trigger
- **Rule**: Zones must be recalculated whenever `age` or `restingHR` changes
- **Rule**: The recalculated zones replace the previous values — no version history is kept in Unit 1

---

## Decision Log

| Decision | Answer | Rationale |
|---|---|---|
| Zone boundary at exact match | Lower zone wins (BR-05) | Common HR training convention; prevents premature zone-up coaching |
| Decimal rounding | Ceiling (BR-03) | Slightly narrower zones; user works marginally harder to enter next zone |
| HR smoothing readings | Always 2 (BR-08) | Matches 10-sec coaching tick (2 readings per tick); simple and consistent |
| avg_hr formula | Simple mean (BR-11) | Sensor fires regularly at 5-sec; time-weighting adds complexity without meaningful accuracy gain |
| Cool-down trigger | User opt-in (BR-10) | Brief explicitly marks cool-down as optional; auto-trigger creates bad UX for time-constrained users |
