# NFR Design Patterns — Unit 1: HeartRateCoachCore

---

## Pattern 1: Input Validation with Typed Errors (SECURITY-05, SECURITY-15)

### Applies To
`ZoneCalculator.calculate(age:restingHR:)`

### Design
`ZoneCalculator` uses Swift's `throws` mechanism with a typed `ZoneCalculationError` enum. Invalid inputs throw a specific error case. The caller uses `do/catch` to show the user a targeted error message and prompt them to re-enter valid values.

```
ZoneCalculationError
  ├── .invalidAge(value: Int)          // age outside 15–100
  └── .invalidRestingHR(value: Int)    // RHR outside 1–219 (hard reject)
```

Note: RHR values in range 40–100 are valid. Values outside 40–100 but within 1–219 produce a **UI warning** (not a thrown error) — the user can proceed after acknowledging. Only physiologically impossible values (≤ 0 or ≥ HRmax) are hard-rejected with a thrown error.

### Error Flow
```
User submits form
  → ViewModel calls ZoneCalculator.calculate(age:restingHR:)
      → Valid input: returns HRZones
      → Invalid input: throws ZoneCalculationError
          → ViewModel catches error
          → Sets errorMessage property
          → SwiftUI View shows inline error
          → User corrects input and retries
```

### Fail-Safe Guarantee (SECURITY-15)
`ZoneCalculator` never returns a plausible-looking but wrong result. If it cannot produce valid zones, it throws. There is no code path that returns default/zeroed zones silently.

---

## Pattern 2: Pure Function Design (Performance + Reliability)

### Applies To
`ZoneCalculator`, `WorkoutPhaseSequencer.advance(by:)`

### Design
All calculation logic is implemented as pure functions or value-type mutations:
- No shared mutable state
- No side effects (no logging, no network calls, no persistence)
- Deterministic — same inputs always produce the same outputs
- Thread-safe by design — structs are copied across thread boundaries

This pattern eliminates the need for locks, actors, or concurrency annotations in Unit 1. Performance requirements (< 1ms per calculation) are met by design.

---

## Pattern 3: Immutable Value Types (Reliability + Thread Safety)

### Applies To
All models: `UserProfile`, `HRZones`, `Zone`, `WorkoutProgram`, `WorkoutPhase`, `Session`, `HRRecord`, `CoachingState`, `HRReading`, `CoachingCommand`

### Design
All domain entities are `struct` (value types). When passed between threads or components, Swift copies them automatically. No reference counting, no shared mutable state, no data races possible.

All properties on models used as public API are `let` (immutable after creation). Mutation produces a new value, not a modified reference.

---

## Pattern 4: Property-Based Test Coverage (Reliability + PBT-02, PBT-03)

### Applies To
`ZoneCalculator`, `WorkoutPhaseSequencer`

### Design
Rather than testing specific examples only, PBT generates hundreds of random `(age, restingHR)` pairs and verifies that invariants hold for all of them. SwiftCheck is used with constrained generators.

**ZoneCalculator invariants verified by PBT:**
- Boundaries are strictly increasing
- No gaps between zones
- zone5.max = HRmax
- Zone classification is consistent with boundaries
- Boundary values classify into lower zone

**WorkoutPhaseSequencer invariants verified by PBT:**
- Total duration equals sum of all phase durations
- Phase index never exceeds phase count
- Grace period deactivates after 10 seconds

---

## Pattern 5: Supply Chain Pinning (SECURITY-10)

### Applies To
SwiftCheck dependency

### Design
SwiftCheck is declared with `exact:` version pinning in `Package.swift`. The generated `Package.resolved` file is committed to git. This ensures:
- Every developer and CI run uses the identical binary
- No unexpected updates break tests
- Dependency provenance is auditable

---

## NFR Category Summary

| Category | Pattern Applied | N/A Reason |
|---|---|---|
| Input Validation | Typed throws (Pattern 1) | — |
| Fail-Safe | No silent failures (Pattern 1) | — |
| Performance | Pure functions (Pattern 2) | — |
| Thread Safety | Immutable value types (Pattern 3) | — |
| Reliability | PBT invariant testing (Pattern 4) | — |
| Supply Chain | Version pinning (Pattern 5) | — |
| Resilience | — | N/A — no external calls |
| Scalability | — | N/A — in-memory |
| Availability | — | N/A — in-process library |
| Auth/Session | — | N/A — no authentication |
| Network | — | N/A — no network |
