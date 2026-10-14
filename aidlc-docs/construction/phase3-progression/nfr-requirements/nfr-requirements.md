# Phase 3 — NFR Requirements (Progression & Assignment)

**Note:** Phase 3 is **pure deterministic logic** (`ProgressionEngine`, `ProgressionTables`, relapse math) plus Home wiring and a lightweight timed minimum-walk flow. Tech stack is fixed; no new transport/auth/storage surface. **No new NFR questions required.** This records the inherited NFRs and what the new work touches.

## Performance
- `assign` / `advance` / `applyRelapse` are O(1) table lookups + arithmetic → sub-millisecond; run on app-open and at session end, never in a hot loop. No concern.

## Reliability / correctness
- **Once-per-gap relapse:** `applyRelapse` stamps `lastCountedSessionDate = now` after applying, so re-opening the app can't re-penalize (BR-3-8). **Requirement:** applying relapse twice without an intervening session is a no-op.
- **Counter integrity:** `sessionsCompleted` is clamped to 0…60; only qualifying sessions advance it (BR-3-5). **Requirement:** no path increments past 60 or below 0.
- **Offline-tolerant:** progression state persists in the existing `v2profile` write (queued if offline); assignment is computed from stored state, so it works offline.
- **Clock skew:** relapse uses day-granularity gaps; a modestly wrong device clock shifts a band at most one step — acceptable, non-safety.

## Data
- One new stored field (`lastCountedSessionDate`) + a `"minimum_walk"` `sessionFlag` value. Negligible size; rides the existing profile/session docs.

## Security (Baseline — Full/blocking)
| Rule | P3 | How |
|---|---|---|
| SECURITY-03 no PII/health in logs | Yes | progression values, dates, assignments never logged (BR-3-12) |
| SECURITY-01 / own-data / consent | Yes | inherited; new state under `users/{uid}.v2profile` |
| SECURITY-02 / 04 | N/A | no new network surface or secrets |

## Testability (PBT partial)
- Pure engine → exhaustive/property tests: §B table coverage, assignment across tracks/leans/sub-phases, advancement gating, relapse bands + plain-subtraction semantics (Q5=B), minimum-walk effects.

## Usability
- Relapse framing **always positive** (§C) — re-entry message is encouraging, not punitive. Minimum-walk is one tap from Home (Q7). Foundation-complete is a celebratory state (Q8).

## Out of scope (later phases)
Push-notification nudge (P6/FR-7), export/PDF (P6), Level Up advance (P4), elevated-HR `walk_fallback` (§J, deferred).
