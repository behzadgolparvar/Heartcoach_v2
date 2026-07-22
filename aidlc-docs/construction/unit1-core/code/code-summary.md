# Code Summary — Unit 1: HeartRateCoachCore

## Generated Files

### Production Code (`HeartRateCoachCore/Sources/HeartRateCoachCore/`)

| File | Contents |
|---|---|
| `Package.swift` | SPM manifest — iOS 17+, watchOS 10+, SwiftCheck test dependency pinned at 0.12.0 |
| `Models/Supporting.swift` | `Goal`, `WorkoutType`, `Sex`, `PhaseType`, `SyncStatus`, `HapticPattern` enums |
| `Models/UserProfile.swift` | User physiological + preference data struct |
| `Models/HRZones.swift` | `Zone` struct + `HRZones` struct (5 zones) |
| `Models/WorkoutProgram.swift` | `WorkoutPhase` struct + `WorkoutProgram` enum with hardcoded phase tables for all 3 programs |
| `Models/Session.swift` | `HRRecord` + `Session` structs |
| `Models/CoachingState.swift` | Live workout snapshot published to UI |
| `Models/Messaging.swift` | `CoachingCommand` enum + `HRReading` struct |
| `Engine/ZoneCalculationError.swift` | `ZoneCalculationError` + `RHRWarning` |
| `Engine/ZoneCalculator.swift` | Karvonen formula implementation |
| `Engine/WorkoutPhaseSequencer.swift` | Phase iteration state machine |

### Test Code (`HeartRateCoachCore/Tests/HeartRateCoachCoreTests/`)

| File | Contents |
|---|---|
| `Helpers/Generators.swift` | SwiftCheck generators: age, RHR, valid/warning/invalid profiles |
| `ZoneCalculatorTests.swift` | 12 example-based + 6 PBT property tests |
| `WorkoutPhaseSequencerTests.swift` | 9 example-based + 1 PBT property test |

---

## Key Implementation Notes

### Zone classification (`ZoneCalculator.zone(for:in:)`)
Uses `<=` for upper boundary checks — this implements "lower zone wins at exact boundary" (BR-05).
The domain-entities.md incorrectly described Zone.max as "exclusive" — the code is authoritative.

### Karvonen formula (`ZoneCalculator.buildZones`)
Each boundary is `ceil(rhr + pct * hrr)` (BR-03 — ceiling rounding).
`zone(n).max` is passed directly as `zone(n+1).min` — no gap possible (BR-04).
`zone5.max = hrMax` (integer, no ceiling needed).

### WorkoutProgram phase tables
All 3 programs use `static let` computed with array construction rather than hardcoded literals:
- Continuous: 2 warm-up + 5 × (exercise + recovery) = 12 phases
- HIIT: 2 warm-up + 15 × (exercise + recovery) = 32 phases
- Fartlek: 2 warm-up + 15 segments = 17 phases

### RHR warning vs error
- `restingHR <= 0` or `restingHR >= hrMax` → throws `ZoneCalculationError.invalidRestingHR`
- `restingHR < 40` or `restingHR > 100` → valid, returns `RHRWarning` alongside zones

---

## PBT Coverage Summary

| Test | Property | Status |
|---|---|---|
| `testZoneBoundariesStrictlyIncreasing` | zone1.max < zone2.max < ... < zone5.max | PBT ✓ |
| `testNoGapsBetweenZones` | zone(n).max == zone(n+1).min | PBT ✓ |
| `testZone5MaxEqualsHRmaxProperty` | zone5.max == 220 - age | PBT ✓ |
| `testZoneClassificationConsistency` | zone(midpoint) returns correct zone number | PBT ✓ |
| `testBoundaryClassificationProperty` | zone(zone.max) returns lower zone | PBT ✓ |
| `testCalculateDeterministic` | same inputs → identical zones | PBT ✓ |
| `testTotalDurationInvariant` | sum(phases.duration) == 2100 for all programs | PBT ✓ |
