# Application Design Plan — HeartRateCoach

## Execution Checklist

- [x] Step 1: Analyze context (requirements.md + stories.md loaded)
- [x] Step 2: Create plan (this document)
- [x] Step 3: Include mandatory artifacts in plan
- [x] Step 4: Generate context-appropriate questions (below)
- [x] Step 5: Store plan (this file)
- [x] Step 6: Request user input → answers received
- [x] Step 7: Collect answers
- [x] Step 8: Analyze answers — no ambiguities found
- [x] Step 9: Follow-up questions — not needed
- [x] Step 10: Generate design artifacts (components.md, component-methods.md, services.md, component-dependency.md, application-design.md)
- [ ] Step 11: Log approval
- [ ] Step 12: Present completion message
- [ ] Step 13: Wait for explicit approval

## Artifacts to Generate

- [x] `aidlc-docs/inception/application-design/components.md`
- [x] `aidlc-docs/inception/application-design/component-methods.md`
- [x] `aidlc-docs/inception/application-design/services.md`
- [x] `aidlc-docs/inception/application-design/component-dependency.md`
- [x] `aidlc-docs/inception/application-design/application-design.md` (consolidated)

---

## Design Questions

The project structure and tech stack are well-defined in the brief. These 4 questions target the key architectural decisions that are NOT already answered and that will significantly affect how all four units are built.

Please fill in the letter after each `[Answer]:` tag.

---

### Question 1
What UI architecture pattern should be used for the SwiftUI views?

A) MVVM — each screen has a dedicated ViewModel (`@Observable` or `ObservableObject`) that holds state and business coordination; Views are purely declarative (recommended for SwiftUI — clean separation, highly testable)
B) MV — Views hold state directly via `@State` and call services/engine directly; no dedicated ViewModels (simpler, less boilerplate, works for smaller apps)
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 2
How should the CoachingEngine be managed during a workout session?

A) Per-session instance — a new `CoachingEngine` is created when a workout starts and discarded when it ends; state is reset automatically between sessions (recommended — clean lifecycle, easier to test)
B) Singleton — one `CoachingEngine` instance lives for the app's lifetime and is reset between sessions
C) Other (please describe after [Answer]: tag below)

[Answer]: A

---

### Question 3
How should reactive data flow be implemented throughout the app (HR updates, coaching state, Firebase sync status)?

A) Combine — `PassthroughSubject` / `CurrentValueSubject` publishers for HR stream, coaching events, and sync status (Apple-native, tight SwiftUI integration via `.onReceive`)
B) Swift Concurrency (async/await + AsyncStream) — `AsyncStream<HRReading>` for HR data, `async` functions for Firebase writes (modern Swift, cleaner syntax, better structured concurrency)
C) Mixed — Swift Concurrency for Firebase async operations, Combine for real-time HR/coaching streams that drive UI (pragmatic — uses the best tool for each job)
D) Other (please describe after [Answer]: tag below)

[Answer]: C

---

### Question 4
How should services (FirebaseService, HealthKitService, WatchBridge) be made available to ViewModels and the CoachingEngine?

A) SwiftUI Environment — services injected via `.environment()` or `@EnvironmentObject`; ViewModels access them through the environment (SwiftUI-native, no boilerplate)
B) Constructor injection — services passed explicitly into each ViewModel/component that needs them (most testable, explicit dependencies, recommended for production-grade code)
C) Other (please describe after [Answer]: tag below)

[Answer]: B

---

Please fill in all answers and let me know when you're done.
