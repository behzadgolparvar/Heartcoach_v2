# v2 Requirements — Clarification Questions

These questions steer the v2 phased plan. Your two spec files supply most requirements; these resolve the decisions that most affect scope and architecture. Answer each by filling the letter after `[Answer]:`. Choose the last option ("Other") to write your own.

---

## Question 1 — Technology
The specs repeatedly assume **Flutter** ("logic runs in Flutter", "Flutter TTS"). Your current app is **native Swift/SwiftUI** with a working Apple Watch HR pipeline, auth, HealthKit, and Firestore.

A) Stay **native Swift/SwiftUI** — reuse everything already working, treat Flutter references as "intended behavior, not tech" (recommended)
B) Rewrite in **Flutter** — matches the spec's wording, but discards the working Watch/HealthKit/auth work
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2 — Reverse Engineering stage
This is a brownfield cycle. AI-DLC would normally run a formal Reverse Engineering stage to document the existing code.

A) **Skip** it — the codebase was already fully analyzed this session; go straight to requirements/planning (recommended)
B) **Run** the formal Reverse Engineering stage and produce the artifacts
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3 — Workout selection model
Today the user picks the workout each session. The spec introduces an **auto-assignment engine** (experience + goal + mentality + monthly progression ratios).

A) Build the **full auto-assignment engine** as specified (Section 2 of the full spec)
B) Start with the **new protocols + coaching**, keep manual selection, add the assignment engine in a later phase
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4 — Reminders (calls/texts)
The spec wants schedule-driven reminders and even flags that automated **calls need Twilio + TTS** (cost/complexity), asking to confirm vs. push notifications.

A) **Push notifications** only for now (local notifications — simple, no external service) (recommended)
B) **Call/text via Twilio** (requires a paid third-party service + backend)
C) **Defer** reminders entirely to a later phase
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5 — Health/medical history fields
The spec collects many fields "stored for future/clinical reference only, no current logic" (chronic conditions, HR meds, smoking, joint issues, Ozempic, occupation).

A) **Collect and store all of them now** (onboarding + Firestore), even though only some drive logic (recommended — cheap, future-proof)
B) **Collect only the fields with active logic** now (age, RHR, experience, goals, mentality, units); add the rest later
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6 — CSV/Excel research export
The spec wants per-session HR-stream export to Firebase Storage (research use, with phrase_type/phrase_time).

A) **Include** the export in this cycle
B) **Defer** to a later phase (focus first on the in-app experience)
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 7 — Delivery approach
How do you want to sequence the work?

A) **Incremental phases**, each shippable to TestFlight — keep `main` releasable, ship value along the way (recommended)
B) **One big v2** — build the whole redesign on the branch, merge/ship only when fully complete
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 8 — Security Baseline extension
Should the SECURITY extension rules be enforced as blocking constraints for v2? (Was "Yes/Full" in v1.)

A) Yes — enforce all SECURITY rules as blocking constraints (recommended)
B) No — skip SECURITY rules
X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 9 — Property-Based Testing extension
Should property-based testing rules be enforced for v2? (Was "Partial" in v1 — core engine only.)

A) Yes — enforce PBT rules broadly (business logic, transformations, serialization)
B) Partial — PBT only for pure functions + serialization round-trips (as v1: zone calc + coaching engine)
C) No — skip PBT
X) Other (please describe after [Answer]: tag below)

[Answer]: B
