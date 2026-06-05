# NFR Requirements — Unit 1: HeartRateCoachCore

## NFR Category Assessment

| Category | Applicable | Reason |
|---|---|---|
| Scalability | N/A | In-memory library; no external resources or connections |
| Performance | Yes | Zone calculation speed directly affects coaching latency |
| Availability | N/A | In-process; no separate deployment or uptime concern |
| Security | Partial | Input validation + supply chain (SwiftCheck dependency) |
| Reliability | Yes | Correctness of zone math is safety-critical |
| Maintainability | Yes | PBT coverage, documentation, Swift version |
| Usability | N/A | No UI in Unit 1 |

---

## Performance Requirements

| Requirement | Target | Rationale |
|---|---|---|
| `ZoneCalculator.calculate()` execution time | < 1ms | Called on onboarding and settings save — synchronous, instant |
| `ZoneCalculator.zone(for:in:)` execution time | < 0.1ms | Called every 5 seconds during workout; must not affect coaching latency |
| `WorkoutPhaseSequencer.advance(by:)` execution time | < 0.1ms | Called every 5 seconds; pure arithmetic |
| Zone recalculation on profile update | < 10ms total | Acceptable for a settings save operation |

All operations are synchronous pure functions — performance requirements are met by design. No async overhead.

---

## Reliability Requirements

| Requirement | Detail |
|---|---|
| Zone boundary correctness | `ZoneCalculator` output must satisfy all 9 testable properties defined in business-logic-model.md |
| Input validation | Invalid inputs (out-of-range age or RHR) must never produce nonsensical zone boundaries — return `.invalid` or throw |
| Determinism | Same inputs must always produce identical outputs — no randomness, no external state |
| No silent failures | Invalid input must fail explicitly (error/nil/Result) — never return plausible-looking wrong data |

---

## Security Requirements (Applicable Rules)

### SECURITY-05: Input Validation
`ZoneCalculator.calculate(age:restingHR:)` receives user-entered data. Must validate:
- `age`: integer, 15 ≤ age ≤ 100
- `restingHR`: integer, 40 ≤ restingHR ≤ 100 (with out-of-range warning per BR-02)
- Reject inputs outside hard bounds — do not produce zone output for invalid input

### SECURITY-10: Supply Chain
- SwiftCheck added via SPM with **exact pinned version** in `Package.resolved`
- `Package.resolved` committed to git — reproducible builds
- No other third-party dependencies in Unit 1

### SECURITY-11: Secure Design
- `ZoneCalculator` is a stateless pure function — no side effects, no shared mutable state ✓
- Health data (RHR, age) flows through Unit 1 only as function parameters — never stored, logged, or persisted ✓

### SECURITY-15: Exception Handling
- `ZoneCalculator` must handle all invalid inputs explicitly — never crash or return silently wrong data
- Recommended: return `Result<HRZones, ZoneCalculationError>` or throw a typed error

### Rules Marked N/A
SECURITY-01, 02, 03, 04, 06, 07, 08, 09, 12, 13, 14 — not applicable to a pure in-memory library with no persistence, network, or authentication.

---

## Testability Requirements

| Requirement | Detail |
|---|---|
| Minimum code coverage | 90%+ for Unit 1 (enforced in CI via Xcode test plan) |
| PBT framework | SwiftCheck — required by PBT-09 |
| PBT scope | `ZoneCalculator` and `WorkoutPhaseSequencer` — all 9 testable properties from business-logic-model.md |
| Example-based tests | Required alongside PBT for all business-critical paths (PBT-10) |
| Seed logging | SwiftCheck seed must be logged on every CI run for reproducibility (PBT-08) |

---

## Maintainability Requirements

| Requirement | Detail |
|---|---|
| Swift version | Swift 5.9 minimum |
| Package type | Local SPM package — clean separation from platform-specific code |
| No platform imports | `HeartRateCoachCore` must import no Apple platform frameworks (no `Foundation`, `UIKit`, `HealthKit`, `WatchKit`) except where unavoidable for `Date` and `UUID` types |
| Documentation | Public API (`ZoneCalculator`, `WorkoutPhaseSequencer`) must have doc comments on all public methods |
