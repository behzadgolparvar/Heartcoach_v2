# Phase 3 — Tech Stack Decisions (Progression & Assignment)

**No new technology decisions.** Phase 3 reuses the fixed stack.

| Concern | Decision | Status |
|---|---|---|
| Progression/assignment/relapse logic | `HeartRateCoachCore` (pure) — `ProgressionEngine`, `ProgressionTables` | Reused package, new types |
| State | `ProgramState` + `StageProgress` (P1b) extended with `lastCountedSessionDate` | Reused |
| Session input | P2 `Session` (`sessionFlag`, scoring, `cooldownSkipped`) | Reused |
| Workout execution | P2 `FoundationSessionManager` | Reused (assignment picks the type) |
| Minimum-walk flow | New lightweight timed flow (voice/timer only; no HR engine) | App, reuses VoiceFeedback |
| Persistence | Firestore `v2profile` / sessions | Reused |
| Testing / project gen | app test target + PBT; xcodegen | Reused |

## Placement
- `ProgressionEngine`, `ProgressionTables`, `SessionRatio`, `SessionAssignment`, relapse types → `HeartRateCoachCore`.
- `ProgramState.lastCountedSessionDate` → core model (P1b type).
- Home "today's session" + override + minimum-walk entry → app `Views/Home`.
- Minimum-walk timed flow → app `Workout/`.

No infrastructure changes → Infrastructure Design **SKIPPED** (consistent with prior phases).
