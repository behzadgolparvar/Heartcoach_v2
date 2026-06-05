# Business Logic Model — Unit 1: HeartRateCoachCore

---

## 1. ZoneCalculator

### 1.1 HRmax Calculation
```
HRmax = 220 - age
```

### 1.2 Heart Rate Reserve (HRR)
```
HRR = HRmax - restingHR
```

### 1.3 Zone Boundary Calculation (Karvonen Formula)
Zone boundaries are calculated as floating-point values, then **ceiled** (rounded up) to the nearest integer.

```
zone1.min = ceil(restingHR + 0.50 × HRR)
zone1.max = ceil(restingHR + 0.60 × HRR)

zone2.min = zone1.max
zone2.max = ceil(restingHR + 0.70 × HRR)

zone3.min = zone2.max
zone3.max = ceil(restingHR + 0.80 × HRR)

zone4.min = zone3.max
zone4.max = ceil(restingHR + 0.90 × HRR)

zone5.min = zone4.max
zone5.max = HRmax  (no ceiling — HRmax is already integer)
```

**Rounding decision**: Ceiling rounding makes zone boundaries slightly narrower — users must work slightly harder to be classified inside a zone.

**Zone boundary continuity**: Each zone's `min` equals the previous zone's `max` — there are no gaps.

### 1.4 HR Zone Classification
Given a raw HR reading (Int) and computed `HRZones`:

```
IF hr < zone1.min  → return 0  (below all zones)
IF hr < zone1.max  → return 1
IF hr < zone2.max  → return 2
IF hr < zone3.max  → return 3
IF hr < zone4.max  → return 4
IF hr <= zone5.max → return 5
IF hr > zone5.max  → return 6  (above HRmax — safety territory)
```

**Boundary rule (Q1 — lower zone wins)**: `< zone.max` (strict less-than) means a reading exactly equal to a boundary is classified in the lower zone.

Example: If zone2.max = 153 and HR = 153 → condition `hr < 153` is false → falls to next check `hr < zone3.max` → Zone 2 (because 153 < zone3.max). ✓

---

## 2. HR Smoothing

Applied by `ZoneCoach` (Unit 3) before zone evaluation. Defined here as the algorithm.

```
INPUTS: hrBuffer: [Int]  — last N raw readings (capacity = 2)
        newReading: Int

ALGORITHM:
  1. Append newReading to hrBuffer
  2. IF hrBuffer.count > 2: remove oldest reading
  3. hrSmooth = sum(hrBuffer) / hrBuffer.count  (integer division)

RESULT: hrSmooth — always based on last 2 readings once buffer is full
        first evaluation (only 1 reading available): hrSmooth = that single reading
```

**Decision (Q3)**: Always 2 readings once buffer is full. At the very start (before second reading arrives), use 1 reading. Buffer capacity = 2.

---

## 3. WorkoutPhaseSequencer

### 3.1 Phase Sequences

#### Continuous Training (35 min total)
| Index | Type | Duration | Target Zone | Grace Period | Instruction |
|---|---|---|---|---|---|
| 0 | warmup | 120s | 1 | No | — |
| 1 | warmup | 180s | 2 | No | — |
| 2 | exercise | 300s | 2 | No | — |
| 3 | recovery | 60s | nil | No | "Walk it out" |
| 4 | exercise | 300s | 3 | No | — |
| 5 | recovery | 60s | nil | No | "Walk it out" |
| 6 | exercise | 300s | 3 | No | — |
| 7 | recovery | 60s | nil | No | "Walk it out" |
| 8 | exercise | 300s | 3 | No | — |
| 9 | recovery | 60s | nil | No | "Walk it out" |
| 10 | exercise | 300s | 4 | No | — |
| 11 | recovery | 60s | nil | No | "Walk it out" |

Total: 120+180+(300+60)×5 = 300+1800 = 2100s = 35 min ✓

#### HIIT Training (35 min total)
| Index | Type | Duration | Target Zone | Grace Period | Instruction |
|---|---|---|---|---|---|
| 0 | warmup | 120s | 1 | No | — |
| 1 | warmup | 180s | 2 | No | — |
| 2–4 | exercise | 60s each | 3 | Yes | — |
| 3–5 (recovery) | recovery | 60s each | nil | No | "Walk it out / don't stop" |
| 5–13 | exercise | 60s each | 4 | Yes | — |
| 6–14 (recovery) | recovery | 60s each | nil | No | "Walk it out / don't stop" |
| 14–16 | exercise | 60s each | 5 | Yes | — |
| 15–17 (recovery) | recovery | 60s each | nil | No | "Walk it out / don't stop" |

Structured as 15 cycles × (60s exercise + 60s recovery) = 1800s + 300s warmup = 2100s = 35 min ✓

Cycle zone assignment:
- Cycles 1–3 (index 2,4,6): Zone 3
- Cycles 4–12 (index 8,10,...,22): Zone 4
- Cycles 13–15 (index 24,26,28): Zone 5

#### Fartlek Training (35 min total)
| Index | Type | Duration | Target Zone | Grace Period |
|---|---|---|---|---|
| 0 | warmup | 120s | 1 | No |
| 1 | warmup | 180s | 2 | No |
| 2–16 | exercise | 120s each | see sequence | Yes |

Zone sequence for segments 2–16 (15 segments):
```
2, 3, 2, 3, 4, 2, 3, 4, 3, 4, 3, 4, 2, 3, 5
```
Total: 120+180+(120×15) = 300+1800 = 2100s = 35 min ✓

### 3.2 Phase Advancement Algorithm
```
STATE:
  currentPhaseIndex: Int = 0
  elapsedInPhase: TimeInterval = 0
  totalElapsed: TimeInterval = 0
  isComplete: Bool = false

ADVANCE(delta: TimeInterval):
  elapsedInPhase += delta
  totalElapsed += delta

  WHILE elapsedInPhase >= currentPhase.duration AND NOT isComplete:
    elapsedInPhase -= currentPhase.duration
    currentPhaseIndex += 1

    IF currentPhaseIndex >= phases.count:
      isComplete = true
      emit .mainWorkoutComplete
      RETURN

    emit .phaseTransition(newPhase: currentPhase)
```

### 3.3 Cool-down Trigger
When `isComplete` becomes `true`, the sequencer emits `.mainWorkoutComplete`. The app presents an optional cool-down prompt to the user. If accepted, a separate cool-down phase sequence begins (user-controlled, not part of the main sequencer).

Cool-down is **not** part of the 35-minute program phase array. It is a separate optional flow triggered by user choice.

### 3.4 Grace Period Tracking
```
isGracePeriodActive:
  IF currentPhase.hasGracePeriod == false → false
  IF elapsedInPhase >= 10.0 → false
  ELSE → true
```

Grace period is active only during the first 10 seconds of a phase that has `hasGracePeriod = true`. Only HIIT and Fartlek exercise phases have this flag set.

---

## 4. Session avg_hr Calculation
```
avgHR = sum(hrStream.map { $0.hr }) / hrStream.count
```
Simple integer mean of all HR readings collected during the session. Applied at workout completion.

---

## 5. Time-in-Zones Calculation
```
FOR each hrRecord in hrStream:
  IF hrRecord.currentZone >= 1 AND hrRecord.currentZone <= 5:
    timeInZones[hrRecord.currentZone] += 5  // each record represents 5 seconds
```

---

## 6. Testable Properties (PBT-01)

The following properties must hold for all valid inputs and are candidates for property-based testing:

| Property | Category | Components |
|---|---|---|
| Zone boundaries are strictly increasing: `zone1.min < zone1.max < zone2.max < ... < zone5.max` | Invariant | `ZoneCalculator` |
| No gaps between zones: `zone(n).max == zone(n+1).min` | Invariant | `ZoneCalculator` |
| `zone5.max == HRmax == 220 - age` | Invariant | `ZoneCalculator` |
| `ZoneCalculator.zone(hr, zones)` returns same result for same inputs | Idempotence | `ZoneCalculator` |
| For any HR in `[zone(n).min, zone(n).max)`, classification returns `n` | Invariant | `ZoneCalculator` |
| HR exactly at boundary `zone(n).max` classifies as zone `n` (lower wins) | Invariant | `ZoneCalculator` |
| `WorkoutPhaseSequencer` total duration == sum of all phase durations | Invariant | `WorkoutPhaseSequencer` |
| `avgHR` is always within `[min(hrStream), max(hrStream)]` | Invariant | Session calculation |
| `sum(timeInZones.values) <= session.durationSec` | Invariant | Session calculation |
