# NFR Requirements Plan — Unit 3: iPhone Workout Engine

## Execution Checklist

- [x] Step 1: Analyze functional design
- [x] Step 2: Create plan (this document)
- [x] Step 3: Generate context-appropriate questions (below)
- [x] Step 4: Store plan (this file)
- [x] Step 5: Collect and analyze answers — no ambiguities; HR staleness rule added from discussion
- [x] Step 6: Generate NFR artifacts
- [ ] Step 7: Present completion message
- [ ] Step 8: Wait for explicit approval

## Artifacts to Generate
- [x] `aidlc-docs/construction/unit3-workout-engine/nfr-requirements/nfr-requirements.md`
- [x] `aidlc-docs/construction/unit3-workout-engine/nfr-requirements/tech-stack-decisions.md`

---

## Context Summary

Unit 3 has three genuine NFR decisions: the 5-second tick timer implementation (Combine vs async/await), voice synthesis language, and WatchConnectivity failure handling. Performance and security requirements are largely determined by design (pure in-memory coaching logic is fast by nature; health data privacy rules from Unit 2 carry forward).

---

## NFR Questions

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
How should the 5-second coaching tick loop be implemented?

A) **`Timer.publish` (Combine)** — `Timer.publish(every: 5, on: .main, in: .common)` drives the tick. Integrates cleanly with Combine pipelines if used elsewhere; fires on the main thread.
B) **`Task` loop with `Task.sleep`** — a detached `Task` runs `while !isComplete { await Task.sleep(nanoseconds: 5_000_000_000); tick() }`. Fits the async/await style used throughout the rest of the app; runs off the main thread.
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

### Question 2
What language/voice should AVSpeechSynthesizer use for coaching cues?

A) **System language** — uses whatever language the iPhone is set to. English phrases like "Speed up" will be spoken in that language's accent/TTS voice.
B) **Explicitly English (en-US)** — always uses `AVSpeechSynthesisVoice(language: "en-US")` regardless of device language. Coaching messages are written in English so English voice always sounds correct.
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

### Question 3
What should happen if a WatchConnectivity haptic command fails to reach the Watch?

A) **Fire and forget** — send the command and move on. If the Watch is unreachable (e.g. out of Bluetooth range), the haptic simply doesn't fire. The coaching cue still appears on-screen and as voice — only the haptic is lost.
B) **Retry once** — if the WCSession send fails, retry once after 1 second. If the second attempt also fails, drop it silently.
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

Please fill in all answers and let me know when you're done.
