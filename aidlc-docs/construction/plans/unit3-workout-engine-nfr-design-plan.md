# NFR Design Plan — Unit 3: iPhone Workout Engine

## Execution Checklist

- [x] Step 1: Analyze NFR requirements
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers
- [x] Step 6: Generate NFR design artifacts
- [x] Step 7: Present completion message
- [x] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit3-workout-engine/nfr-design/nfr-design-patterns.md`
- [x] `aidlc-docs/construction/unit3-workout-engine/nfr-design/logical-components.md`

---

## Context Summary

Most Unit 3 NFR patterns flow directly from decisions already made:
- Task loop pause/resume → cancel + recreate pattern ✓
- HR staleness tracking → lastHRReceived timestamp ✓
- Layer mutual exclusion → early return in tick() ✓
- Anti-spam → timestamp comparison ✓
- Voice interruption → stopSpeaking before speak ✓

One genuine design decision remains: whether `CoachingEngine` state is isolated as a separate injectable struct (better for PBT) or held as private properties on the class.

---

## NFR Design Question

Please fill in the letter after the `[Answer]:` tag.

---

### Question 1
How should `CoachingEngine` internal state be structured for testability and PBT?

A) **Isolated state struct** — `CoachingEngineState` is a separate `struct` (value type) passed into `tick()` as an `inout` parameter and returned mutated. The engine itself is stateless. Tests can construct any starting state and verify outputs deterministically.
   ```swift
   static func tick(hr: Int, phase: WorkoutPhase, elapsedInPhase: TimeInterval,
                    state: inout CoachingEngineState,
                    zones: HRZones) -> CoachingMessage?
   ```

B) **Properties on class** — `CoachingEngineState` properties (`hrBuffer`, `lastLayer2MessageAt`, etc.) live directly on the `CoachingEngine` class. Tests create a `CoachingEngine` instance, feed it ticks, and inspect results.
   ```swift
   func tick(hr: Int, phase: WorkoutPhase, elapsedInPhase: TimeInterval) -> CoachingMessage?
   ```

C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in your answer and let me know when you're done.
