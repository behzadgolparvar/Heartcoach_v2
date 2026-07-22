# Code Generation Plan — Unit 1: HeartRateCoachCore

## Unit Context

- **Unit**: HeartRateCoachCore (Local SPM Package)
- **Location**: `HeartRateCoachCore/` at workspace root `/Users/behzad/Heartcoach_v2/`
- **Language**: Swift 5.9
- **Dependencies**: Foundation (standard library), SwiftCheck 0.12.0 (test only)
- **Stories covered**: None directly (foundational layer used by Units 2–4)
- **Depends on**: Nothing
- **Required by**: Unit 2 (iPhone Foundation), Unit 4 (Apple Watch App)

## Design Sources
- `aidlc-docs/construction/unit1-core/functional-design/domain-entities.md`
- `aidlc-docs/construction/unit1-core/functional-design/business-logic-model.md`
- `aidlc-docs/construction/unit1-core/functional-design/business-rules.md`
- `aidlc-docs/construction/unit1-core/nfr-design/nfr-design-patterns.md`
- `aidlc-docs/construction/unit1-core/nfr-design/logical-components.md`

---

## Generation Checklist

### Phase 1: Project Structure Setup

- [x] **Step 1** — Create `HeartRateCoachCore/Package.swift`
  - SPM manifest with iOS 17+, watchOS 10+ platforms
  - Production target: `HeartRateCoachCore` (no dependencies)
  - Test target: `HeartRateCoachCoreTests` (depends on HeartRateCoachCore + SwiftCheck 0.12.0)
  - SwiftCheck URL + exact version pinned

- [x] **Step 2** — Create directory structure
  ```
  HeartRateCoachCore/
    Sources/HeartRateCoachCore/
      Models/
      Engine/
    Tests/HeartRateCoachCoreTests/
      Helpers/
  ```

---

### Phase 2: Supporting Enums

- [x] **Step 3** — Create `Sources/HeartRateCoachCore/Models/Supporting.swift`
  - `Goal`: `.fatBurn`, `.endurance`
  - `WorkoutType`: `.continuous`, `.hiit`, `.fartlek`
  - `Sex`: `.male`, `.female`, `.other`
  - `PhaseType`: `.warmup`, `.exercise`, `.recovery`, `.cooldown`
  - `SyncStatus`: `.synced`, `.savedLocally`, `.syncing`, `.failed`
  - `HapticPattern`: `.short`, `.long`, `.doubleTap`, `.emergencyRepeated`

---

### Phase 3: Domain Models

- [x] **Step 4** — Create `Sources/HeartRateCoachCore/Models/UserProfile.swift`
  - `struct UserProfile` with all properties per domain-entities.md

- [x] **Step 5** — Create `Sources/HeartRateCoachCore/Models/HRZones.swift`
  - `struct Zone` (number, name, min, max)
  - `struct HRZones` (zone1–zone5)

- [x] **Step 6** — Create `Sources/HeartRateCoachCore/Models/WorkoutProgram.swift`
  - `struct WorkoutPhase` with all properties
  - `enum WorkoutProgram` with `.continuous`, `.hiit`, `.fartlek`
  - Each case provides `var phases: [WorkoutPhase]` with the complete hardcoded phase sequences from business-logic-model.md
    - Continuous: 12 phases (warm-up × 2 + 5 × exercise/recovery)
    - HIIT: 32 phases (warm-up × 2 + 15 × exercise/recovery)
    - Fartlek: 17 phases (warm-up × 2 + 15 × segments)

- [x] **Step 7** — Create `Sources/HeartRateCoachCore/Models/Session.swift`
  - `struct HRRecord` with all properties
  - `struct Session` with all properties

- [x] **Step 8** — Create `Sources/HeartRateCoachCore/Models/CoachingState.swift`
  - `struct CoachingState` with all published UI properties

- [x] **Step 9** — Create `Sources/HeartRateCoachCore/Models/Messaging.swift`
  - `enum CoachingCommand` with all cases
  - `struct HRReading`

---

### Phase 4: Engine — Error Types

- [x] **Step 10** — Create `Sources/HeartRateCoachCore/Engine/ZoneCalculationError.swift`
  - `enum ZoneCalculationError: Error` with `.invalidAge(value: Int)`, `.invalidRestingHR(value: Int)`
  - `enum RHRWarning` with `.belowTypicalRange`, `.aboveTypicalRange`

---

### Phase 5: Engine — ZoneCalculator

- [x] **Step 11** — Create `Sources/HeartRateCoachCore/Engine/ZoneCalculator.swift`
  - `struct ZoneCalculator` (static methods only)
  - `static func maxHR(for age: Int) -> Int`
  - `static func calculate(age: Int, restingHR: Int) throws -> (zones: HRZones, warning: RHRWarning?)`
    - Validate age (15–100), throw `.invalidAge` if outside
    - Validate restingHR (> 0 and < HRmax), throw `.invalidRestingHR` if invalid
    - Return `RHRWarning` if restingHR outside 40–100 (but still calculate zones)
    - Apply Karvonen formula with ceiling rounding (BR-03)
    - Ensure `zone(n).max == zone(n+1).min` (BR-04)
  - `static func zone(for hr: Int, in zones: HRZones) -> Int`
    - Returns 0 (below), 1–5 (in zone), 6 (above HRmax)
    - Uses strict less-than for upper boundary (BR-05)
  - Full doc comments on all public methods

---

### Phase 6: Engine — WorkoutPhaseSequencer

- [x] **Step 12** — Create `Sources/HeartRateCoachCore/Engine/WorkoutPhaseSequencer.swift`
  - `struct WorkoutPhaseSequencer`
  - `init(program: WorkoutProgram)`
  - `var currentPhase: WorkoutPhase`
  - `var timeRemainingInPhase: TimeInterval`
  - `var isGracePeriodActive: Bool` (true if phase.hasGracePeriod && elapsedInPhase < 10.0)
  - `var isComplete: Bool`
  - `mutating func advance(by seconds: TimeInterval) -> SequencerEvent`
    - `enum SequencerEvent`: `.none`, `.phaseTransition(WorkoutPhase)`, `.mainWorkoutComplete`
  - Full doc comments on all public methods

---

### Phase 7: Tests — Helpers

- [x] **Step 13** — Create `Tests/HeartRateCoachCoreTests/Helpers/Generators.swift`
  - Import SwiftCheck
  - `AgeGenerator`: `Gen<Int>` constrained to 15–100
  - `InvalidAgeGenerator`: negative/zero + above 100
  - `RestingHRGenerator`: `Gen<Int>` constrained to 40–100
  - `WarningRHRGenerator`: 1–39 and 101–219
  - `InvalidRHRGenerator`: 0 and negative
  - `ValidProfileGenerator`: `Gen<(age: Int, restingHR: Int)>` — valid pairs

---

### Phase 8: Tests — ZoneCalculator

- [x] **Step 14** — Create `Tests/HeartRateCoachCoreTests/ZoneCalculatorTests.swift`

  **Example-based tests:**
  - `testKarvonenFormulaKnownValues()` — manual calculation for age 30, RHR 60; verify all 5 zone boundaries
  - `testMaxHR()` — age 30 → HRmax = 190
  - `testZone5MaxEqualsHRmax()` — zone5.max = HRmax for known inputs
  - `testBoundaryLowerZoneWins()` — HR exactly at zone2.max → returns zone 2
  - `testHRBelowAllZones()` — HR < zone1.min → returns 0
  - `testHRAboveHRmax()` — HR > HRmax → returns 6
  - `testCeilingRounding()` — verify boundaries are ceiled
  - `testRHRWarningBelowRange()` — RHR 35 → returns warning + valid zones
  - `testRHRWarningAboveRange()` — RHR 110 → returns warning + valid zones
  - `testInvalidAgeLow()` — age 10 → throws `.invalidAge`
  - `testInvalidAgeHigh()` — age 105 → throws `.invalidAge`
  - `testInvalidRHRZero()` — restingHR 0 → throws `.invalidRestingHR`

  **Property-based tests (SwiftCheck):**
  - `testZoneBoundariesStrictlyIncreasing()` — for all valid (age, rhr): zone1.max < zone2.max < zone3.max < zone4.max < zone5.max
  - `testNoGapsBetweenZones()` — for all valid (age, rhr): zone(n).max == zone(n+1).min
  - `testZone5MaxEqualsHRmaxProperty()` — for all valid (age, rhr): zone5.max == 220 - age
  - `testZoneClassificationConsistency()` — for any HR in [zone(n).min, zone(n).max), zone() returns n
  - `testBoundaryClassificationProperty()` — HR == zone(n).max → zone() returns n (lower zone wins)
  - `testCalculateDeterministic()` — same (age, rhr) always produces identical HRZones

---

### Phase 9: Tests — WorkoutPhaseSequencer

- [x] **Step 15** — Create `Tests/HeartRateCoachCoreTests/WorkoutPhaseSequencerTests.swift`

  **Example-based tests:**
  - `testContinuousTotalDuration()` — sum of all phase durations = 2100s
  - `testHIITTotalDuration()` — sum = 2100s
  - `testFartlekTotalDuration()` — sum = 2100s
  - `testPhaseAdvancement()` — advance past first phase; verify transition event fired
  - `testGracePeriodActiveFirst10Seconds()` — HIIT exercise phase; advance 5s → grace period active
  - `testGracePeriodInactiveAfter10Seconds()` — HIIT exercise phase; advance 11s → grace period inactive
  - `testGracePeriodNotApplicableToContinuous()` — Continuous exercise phase → grace period always false
  - `testWorkoutCompleteSignalFired()` — advance past all phases → `.mainWorkoutComplete`
  - `testFartlekZoneSequence()` — verify zones follow `2,3,2,3,4,2,3,4,3,4,3,4,2,3,5`

  **Property-based tests (SwiftCheck):**
  - `testTotalDurationInvariant()` — for all programs: sum(phases.map(\.duration)) == 2100

---

### Phase 10: Documentation

- [x] **Step 16** — Create `aidlc-docs/construction/unit1-core/code/code-summary.md`
  - List of all generated files with paths
  - Key implementation notes (ceiling rounding, lower-zone-wins, throws pattern)
  - PBT coverage summary

---

## Total: 16 steps across 10 phases

| Phase | Steps | Contents |
|---|---|---|
| 1 — Project Structure | 1–2 | Package.swift + directories |
| 2 — Supporting Enums | 3 | Goal, WorkoutType, Sex, PhaseType, SyncStatus, HapticPattern |
| 3 — Domain Models | 4–9 | UserProfile, HRZones, WorkoutProgram, Session, CoachingState, Messaging |
| 4 — Error Types | 10 | ZoneCalculationError, RHRWarning |
| 5 — ZoneCalculator | 11 | Full Karvonen implementation + throws |
| 6 — WorkoutPhaseSequencer | 12 | Phase iteration + grace period |
| 7 — Test Helpers | 13 | SwiftCheck generators |
| 8 — ZoneCalculator Tests | 14 | 12 example-based + 6 PBT tests |
| 9 — Sequencer Tests | 15 | 9 example-based + 1 PBT test |
| 10 — Documentation | 16 | code-summary.md |
