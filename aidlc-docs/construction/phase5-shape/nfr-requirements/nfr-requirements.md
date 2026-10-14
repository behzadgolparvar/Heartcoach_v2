# Phase 5 — NFR Requirements (Shape)

**Note:** Phase 5 is pure logic (`WeightExerciseBank`, `ShapeExercisePlanner`, `ShapeProtocolBuilder`) + a per-session Option A/B + muscle picker + the Shape-HIIT coaching cadence on the existing engine. Tech stack fixed; reuses P2/P3/P4. **No new NFR questions required.**

## Performance
- Planner (role pattern + per-muscle seeded pick) and builder run once at session start → negligible.
- Shape-HIIT 2-checks cadence is a tick-scheduling change (fewer ticks than 15s) → no added cost.
- **Requirement:** no measurable change to session-start or tick latency vs Level Up.

## Reliability / safety
- **Exactly-2 muscle validation (BR-5-2)** prevents a malformed Option B session (can't start without 2 distinct ordered muscles).
- **Legs rule / injury exclusion:** leg phases reuse the P4 eligible-pool safeguard — a reported injured joint never yields an excluded plyometric move; empty pool degrades safely.
- Run-phase HR safety (HR>max emergency) + §J reuse P2 unchanged; `.exercise` phases non-scored.
- Offline-tolerant: `ShapeUnlock` + program persist via the existing profile write.

## Security (Baseline — Full/blocking)
| Rule | P5 | How |
|---|---|---|
| SECURITY-03 no PII/health in logs | Yes | muscle picks, exercise selections, assignments never logged (BR-5-19) |
| SECURITY-01 / own-data / consent | Yes | `ShapeUnlock` under `users/{uid}.v2profile`; inherited |
| SECURITY-02 / 04 | N/A | no new network surface or secrets |

## Testability (PBT partial)
- Pure planner/builder/banks → exhaustive/property tests: 4-2 & 6-5 patterns, role→muscle, Legs rule rep counts, Option A all-legs, injury exclusion, both timelines + %HRR + scored set, weight-bank counts.

## Usability / accessibility
- Per-session Option A/B + muscle picker defaults from unlock (one-tap typical day).
- Exercise cues (name + reps + switch-legs) + rep progress have on-screen equivalents (voice-off, reused).
- Shape-complete is a celebratory "Maintain coming soon" state.

## Out of scope
Milestones/reminders/export/PDF (P6), Maintain. §J `walk_fallback` + P4/P5 device refinements → Build & Test.
