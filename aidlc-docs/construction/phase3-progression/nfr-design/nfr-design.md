# Phase 3 — NFR Design (Progression & Assignment)

How the NFR requirements are realized. Concise; concrete patterns + placements.

## 1. Purity / determinism pattern
- `ProgressionEngine` is a set of **pure static functions** (`assign`, `advance`, `applyRelapse`) over value inputs (profile/program snapshot + a clock date passed in). No I/O, no hidden state, no global `Date()` inside — the caller passes `now`, so relapse is deterministic and testable.
- `ProgressionTables` are **immutable static data** matching §B; one source of truth, indexed by `(track, lean, subPhase)`.
- Ratio-cycle expansion is a pure function of the ratio → reproducible assignment, no RNG (Q1=A).

## 2. Correctness patterns
- **Clamp at the boundaries:** `advance` does `min(60, n+1)`; `applyRelapse` does `max(0, n−N)` and `reset → 0` (Q5=B). Invariant `0 ≤ sessionsCompleted ≤ 60` holds by construction.
- **Once-per-gap:** `applyRelapse` returns the new program with `lastCountedSessionDate = now`; the app persists it immediately, so a second call before any session finds gap ≈ 0 → `none`. Idempotent re-entry.
- **Single advance path:** only the session-completion handler calls `advance`, and only for a qualifying `Session` (BR-3-5). The minimum walk uses a **separate** path that stamps the date but never calls `advance` — the two can't be confused.

## 3. Reliability / offline
- Progression state lives in `v2profile.program` and is written with the existing offline-tolerant profile save; assignment reads stored state, so Home works offline. A queued write syncs later without affecting local assignment.

## 4. Security pattern (SECURITY-03)
- Engine and tables contain **no logging**. Code-Gen gets the same grep-check used in P1b/P2 over the new types (`ProgressionEngine`, `ProgressionTables`, relapse/assignment fields, `lastCountedSessionDate`) → zero logging hits. New state rides the existing own-data document (SECURITY-01); no new auth/network surface (02/04 N/A).

## 5. Testability pattern
- `now` injected into relapse (not `Date()` internally) → tests set exact gaps.
- Pure functions → exhaustive table/property tests without mocks (tracks × leans × sub-phases; §C bands; clamp boundaries 0/60).

## 6. Usability pattern
- Relapse outcome carries `band` + before/after counts so the app can render an **encouraging** re-entry line (§C positive framing), never a bare "−5".
- Minimum walk is a distinct, always-available Home action; Foundation-complete is a dedicated celebratory state (Q8) that later becomes the P4 Level Up unlock.

## 7. Component / placement map
| Concern | Component | Location |
|---|---|---|
| Ratio tables | `ProgressionTables` | `HeartRateCoachCore` |
| Assignment/advancement/relapse | `ProgressionEngine`, `SessionRatio`, `SessionAssignment`, `RelapseBand/Outcome` | `HeartRateCoachCore` |
| `lastCountedSessionDate` | `ProgramState` (P1b) | `HeartRateCoachCore` |
| Home "today's session" + override + minimum entry | Home view/VM | app `Views/Home` |
| Minimum-walk timed flow | new lightweight manager | app `Workout/` |
| Session-complete → advance; relapse on open | wiring | app VMs |

## 8. Infrastructure Design — SKIPPED
No new infrastructure. Consistent with prior phases.
