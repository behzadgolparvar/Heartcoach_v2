# Tech Stack Decisions — Unit 1: HeartRateCoachCore

## Language

| Decision | Choice | Rationale |
|---|---|---|
| Swift version | **Swift 5.9** | Stable, `@Observable` available; value types in Unit 1 are `Sendable` by default — no concurrency friction |
| Language mode | Standard (not Swift 6 strict) | Pure value types throughout Unit 1; strict concurrency mode adds no safety benefit here |

---

## Package Structure

| Decision | Choice | Rationale |
|---|---|---|
| Packaging | **Local SPM Package** | Clean separation from platform-specific code; importable by both iPhone and Watch targets |
| Package name | `HeartRateCoachCore` | Descriptive, matches project naming convention |
| Minimum platform | iOS 17.0, watchOS 10.0 | Matches project-wide deployment targets |
| External imports | `Foundation` only (for `Date`, `UUID`) | No UIKit, HealthKit, WatchKit, or Firebase — keeps package pure and cross-platform |

### Package.swift Structure
```swift
// Package.swift
let package = Package(
    name: "HeartRateCoachCore",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "HeartRateCoachCore", targets: ["HeartRateCoachCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", exact: "0.12.0")
    ],
    targets: [
        .target(name: "HeartRateCoachCore", dependencies: []),
        .testTarget(
            name: "HeartRateCoachCoreTests",
            dependencies: ["HeartRateCoachCore", "SwiftCheck"]
        )
    ]
)
```

Note: SwiftCheck is a **test-only** dependency — it is not imported into the production `HeartRateCoachCore` target, only into the test target.

---

## Testing Stack

| Decision | Choice | Rationale |
|---|---|---|
| Unit test runner | **XCTest** | Standard Apple test framework; Xcode-native; required for SwiftCheck integration |
| PBT framework | **SwiftCheck 0.12.0** | Most mature Swift PBT framework; supports custom generators, automatic shrinking, seed reproducibility, XCTest integration (PBT-09 ✓) |
| Coverage tool | **Xcode Code Coverage** | Built into Xcode test plans; enforces 90%+ gate |
| Coverage gate | **90% minimum** | Enforced via Xcode test plan configuration |

### SwiftCheck — Why This Version
- Version 0.12.0 is the latest stable release
- Pinned via `exact:` in `Package.resolved` for supply chain compliance (SECURITY-10)
- Supports Swift 5.9+ ✓

---

## Dependency Summary

| Dependency | Version | Scope | Purpose |
|---|---|---|---|
| SwiftCheck | 0.12.0 (exact) | Test only | Property-based testing for ZoneCalculator + WorkoutPhaseSequencer |

No production dependencies beyond Swift standard library and Foundation.

---

## Security Compliance Summary (Unit 1)

| Rule | Status | Notes |
|---|---|---|
| SECURITY-01 | N/A | No persistence |
| SECURITY-02 | N/A | No network |
| SECURITY-03 | N/A | No logging needed in pure domain library |
| SECURITY-04 | N/A | No web/HTTP |
| SECURITY-05 | Compliant | Input validation on `ZoneCalculator.calculate()` per BR-01/BR-02 |
| SECURITY-06 | N/A | No permissions/IAM |
| SECURITY-07 | N/A | No network config |
| SECURITY-08 | N/A | No auth/access control |
| SECURITY-09 | N/A | No deployable component |
| SECURITY-10 | Compliant | SwiftCheck pinned with exact version; `Package.resolved` committed |
| SECURITY-11 | Compliant | `ZoneCalculator` isolated pure function; health data not stored/logged |
| SECURITY-12 | N/A | No authentication |
| SECURITY-13 | N/A | No external data deserialization |
| SECURITY-14 | N/A | No deployed service |
| SECURITY-15 | Compliant | Invalid inputs handled explicitly — no silent failures |

---

## PBT Compliance Summary (Unit 1 — Partial Enforcement)

| Rule | Status | Notes |
|---|---|---|
| PBT-02 | Planned | Round-trip: ZoneCalculator zone classification round-trip (zone → HR in range → same zone) |
| PBT-03 | Planned | Invariants: monotonic boundaries, no gaps, zone5.max = HRmax |
| PBT-07 | Planned | Custom generators: constrained `age` (15–100) and `restingHR` (40–100) generators |
| PBT-08 | Planned | SwiftCheck logs seed on failure; CI will log seed on every run |
| PBT-09 | Compliant | SwiftCheck selected and documented; added as test dependency |
| PBT-01, 04, 05, 06, 10 | Advisory | Partial enforcement mode — not blocking for Unit 1 |
