# Logical Components — Unit 1: HeartRateCoachCore

Unit 1 has no infrastructure components (no queues, caches, circuit breakers, or external services). The logical components below are the design elements that support the NFR patterns.

---

## ZoneCalculationError (Typed Error Enum)

**Purpose**: Carries specific failure reason from `ZoneCalculator` to callers, enabling targeted user-facing error messages.

```swift
enum ZoneCalculationError: Error {
    case invalidAge(value: Int)        // age < 15 or age > 100
    case invalidRestingHR(value: Int)  // restingHR <= 0 or restingHR >= HRmax
}
```

**Used by**: `OnboardingViewModel`, `SettingsViewModel` — both catch specific cases and set UI error messages accordingly.

---

## RHRWarning (Soft Validation Signal)

**Purpose**: Signals that RHR is outside the typical 40–100 range but not invalid. Distinct from `ZoneCalculationError` — does not stop zone calculation.

```swift
enum RHRWarning {
    case belowTypicalRange   // RHR < 40
    case aboveTypicalRange   // RHR > 100
}
```

`ZoneCalculator.calculate()` returns `(zones: HRZones, warning: RHRWarning?)` — zones are calculated and the optional warning is surfaced to the UI alongside them.

**User experience**: Zone calculation proceeds, but UI shows: *"This value is outside the typical range. Please confirm it is correct."* User can continue.

---

## SwiftCheck Generators (Test-Only Components)

These components live in the test target only and are never shipped in production.

### AgeGenerator
```swift
// Generates valid ages: 15–100
let validAge: Gen<Int> = Gen<Int>.choose((15, 100))

// Generates invalid ages for negative testing
let invalidAge: Gen<Int> = Gen<Int>.one(of: [
    Gen<Int>.choose((-100, 0)),    // negative/zero
    Gen<Int>.choose((101, 200))    // above maximum
])
```

### RestingHRGenerator
```swift
// Generates valid RHR values: 40–100
let validRHR: Gen<Int> = Gen<Int>.choose((40, 100))

// Generates edge-case RHR: 1–39 and 101–219 (warning range)
let warningRHR: Gen<Int> = Gen<Int>.one(of: [
    Gen<Int>.choose((1, 39)),
    Gen<Int>.choose((101, 219))
])

// Generates hard-invalid RHR
let invalidRHR: Gen<Int> = Gen<Int>.one(of: [
    Gen.pure(0),
    Gen<Int>.choose((-100, -1))
])
```

### UserProfileGenerator
```swift
// Generates valid (age, restingHR) pairs for ZoneCalculator PBT
let validProfile: Gen<(age: Int, restingHR: Int)> = validAge.flatMap { age in
    validRHR.map { rhr in (age: age, restingHR: rhr) }
}
```

**Reuse**: These generators are defined once in a `Generators.swift` test helper file and imported by all test files that need them (PBT-07 — reusable generators).

---

## Test Structure

```
HeartRateCoachCoreTests/
  Helpers/
    Generators.swift          // All SwiftCheck generators (reusable)
  ZoneCalculatorTests.swift   // PBT + example-based tests
  WorkoutPhaseSequencerTests.swift
  SessionCalculationTests.swift
```

**Separation** (PBT-10): Each test file clearly separates PBT from example-based tests using `// MARK: - Property-Based Tests` and `// MARK: - Example-Based Tests` sections.

---

## Error Handling Contract

| Scenario | Mechanism | User Experience |
|---|---|---|
| age < 15 or age > 100 | throws `.invalidAge` | Inline form error, stays on screen |
| restingHR ≤ 0 | throws `.invalidRestingHR` | Inline form error, stays on screen |
| restingHR outside 40–100 | returns `RHRWarning` | Warning banner shown, user can proceed |
| restingHR valid | returns `HRZones` (no warning) | Normal flow, navigate forward |
