# NFR Design Plan — Unit 1: HeartRateCoachCore

## Execution Checklist

- [x] Step 1: Analyze NFR requirements
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers — no ambiguities
- [x] Step 6: Generate NFR design artifacts
- [ ] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit1-core/nfr-design/nfr-design-patterns.md`
- [x] `aidlc-docs/construction/unit1-core/nfr-design/logical-components.md`

---

## Context Summary

NFR categories assessed:
- **Resilience**: N/A — pure in-memory library, no external calls, no retry needed
- **Scalability**: N/A — runs on-device, scales with hardware
- **Performance**: Handled by design — pure synchronous functions are inherently fast
- **Security**: One pattern needed — input validation + fail-safe error signaling
- **Logical Components**: SwiftCheck test generator components needed for PBT

Only **one genuine design decision** remains: how `ZoneCalculator` signals invalid input to its callers.

---

## NFR Design Question

Please fill in the letter after the `[Answer]:` tag.

---

### Question 1
How should `ZoneCalculator.calculate(age:restingHR:)` signal invalid input to its callers?

A) **`throws` + typed error** — `func calculate(age: Int, restingHR: Int) throws -> HRZones` with a `ZoneCalculationError` enum (`.invalidAge`, `.invalidRestingHR`). Caller uses `try/catch`. Clean, explicit, Swift-idiomatic.
B) **`Result<HRZones, ZoneCalculationError>`** — returns a result type; caller pattern-matches on `.success`/`.failure`. No `try` needed; useful when callers want to handle errors without `do/catch` blocks.
C) **`Optional<HRZones>`** — returns `nil` on invalid input. Simplest call site (`let zones = ZoneCalculator.calculate(...)` with optional binding), but loses information about *why* it failed.
D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in your answer and let me know when you're done.
