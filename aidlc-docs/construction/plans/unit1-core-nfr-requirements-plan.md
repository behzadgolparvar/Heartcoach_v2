# NFR Requirements Plan — Unit 1: HeartRateCoachCore

## Execution Checklist

- [x] Step 1: Analyze functional design
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers — no ambiguities
- [x] Step 6: Generate NFR artifacts
- [ ] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit1-core/nfr-requirements/nfr-requirements.md`
- [x] `aidlc-docs/construction/unit1-core/nfr-requirements/tech-stack-decisions.md`

---

## Context Summary

Unit 1 is a pure in-memory Swift library — no network, no database, no UI. Most NFR categories (scalability, availability, security at rest) are N/A. The 3 questions below target the genuine decisions: PBT framework selection (required by PBT-09), Swift language version, and code coverage targets.

---

## NFR Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
Which property-based testing framework should be used for `ZoneCalculator` and `WorkoutPhaseSequencer`? (Required by PBT-09 — must support custom generators, shrinking, and seed-based reproducibility with XCTest.)

A) **SwiftCheck** — the most mature Swift PBT framework (port of Haskell's QuickCheck); supports custom generators, automatic shrinking, seed reproducibility, XCTest integration; added via SPM (recommended)
B) **Genything** — newer Swift-native PBT framework; less mature than SwiftCheck but more idiomatic Swift syntax
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
Which Swift language version should HeartRateCoachCore target?

A) **Swift 5.9** — stable, `@Observable` available, no strict concurrency enforcement; safe choice for a first version
B) **Swift 6** — enables strict concurrency checking (`Sendable`, actor isolation); catches data race issues at compile time but requires more careful model design (value types in Unit 1 are already `Sendable` by default, so impact is minimal)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 3
What minimum test coverage target should be enforced for Unit 1 in CI?

A) **90%+** — high coverage; every branch of ZoneCalculator and WorkoutPhaseSequencer is tested (recommended given PBT is already in place)
B) **80%** — standard target; allows some minor utility code to be untested
C) No enforced minimum — rely on PBT and manual review
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in all answers and let me know when you're done.
