# Phase 4 — NFR Requirements (Level Up)

**Note:** Phase 4 is pure logic (`LegExerciseBank`, `ExerciseSelector`, `LevelUpProtocolBuilder`) + an exercise-cue layer on the existing P2 session engine + an unlock screen. Tech stack fixed; reuses P2 coaching/cooldown/scoring and P3 progression. **No new NFR questions required.** Inherited NFRs + deltas below.

## Performance
- `ExerciseSelector` (filter + seeded shuffle) and `LevelUpProtocolBuilder` run once at session start over an 8-item bank / ~40-phase timeline → negligible.
- Exercise-cue rep count is a per-second timeline tick (no HR, no allocation growth), same cadence budget as P2.
- **Requirement:** no measurable change to session-start or tick latency vs Foundation.

## Reliability / safety
- **Empty-pool safeguard (BR-4-5):** exclusions can never produce an assigned excluded exercise or a crash — selector degrades to lowest-impact eligible or run-only with a caution. **Requirement (safety):** a reported injured joint must never yield an exercise tagged with that joint.
- Exercise phases are not HR-scored; run-phase scoring + §J safety reuse P2 unchanged (HR>max emergency stays live in all run phases).
- Offline-tolerant: `LevelUpUnlock` + program persist via the existing profile write.

## Security (Baseline — Full/blocking)
| Rule | P4 | How |
|---|---|---|
| SECURITY-03 no PII/health in logs | **Yes** | injury/joint data, exercise picks, assignments never logged (BR-4-17) |
| SECURITY-01 / own-data / consent | Yes | `LevelUpUnlock` under `users/{uid}.v2profile`; inherited |
| SECURITY-02 / 04 | N/A | no new network surface or secrets |

## Testability (PBT partial)
- Pure selector/builder/mapping → exhaustive/property tests: exclusion per joint, comfort-subset, no-repeat sequence, both protocol timelines + %HRR + scored set, mode→timing, `jointIssues`→`LegJoint`.

## Usability / accessibility
- Injury caution shown once at unlock (§E copy, BR-4-6).
- Synced rep count + exercise name have on-screen text equivalents (voice-off fallback, reuses P2 pattern); "switch legs" visible for unilateral.

## Out of scope
Shape (P5), milestones/reminders/export/PDF (P6), Maintain. §J `walk_fallback` still deferred (Build & Test).
