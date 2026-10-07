# Phase 2 — NFR Requirements (Foundation Protocols + Coaching)

**Note:** the new Phase 2 work is pure domain logic (`FoundationProtocolBuilder`, `CoachingEngineV2`, `SessionScorer`, `BriefingPolicy`) plus wiring onto the **already-shipped v1 real-time infrastructure** (Watch HR pipeline / `WCSession`, voice + haptics, audio session, session-manager tick loop, Firestore offline-tolerant saves). Tech stack and transport are fixed. **No new NFR questions were required** — nothing ambiguous. This records the inherited NFRs and the few the new work touches.

## Performance (real-time)
- Coaching tick runs every **15s** (off-zone) with a **5s** safety sub-check — the cadence the v1 engine already sustains. `CoachingEngineV2.tick` is O(1) over a handful of pools → sub-millisecond; no regression vs v1.
- `FoundationProtocolBuilder.build` runs **once per session start** (builds ~13–40 phases) → negligible.
- `SessionScorer` runs **once at training end** over the per-second stream (~1200–2100 records) → linear, sub-10ms.
- **Requirement:** no added latency to HR→coaching response vs v1; no per-tick allocation growth over a 37-min session.

## Reliability
- **Safety liveness (blocking):** HR > `effectiveMaxHR` must trigger emergency stop within one 5s safety check in every phase except sensor-dropout/pause (BR-2-23). Reuses v1 safety path.
- **Sensor dropout / pause / cancel / walk-fallback** per §J (BR-2-24…27) — resume-in-place, data-gap flag, ≥20-min scoring rule.
- **Offline-tolerant save:** session + phase-tagged `hr_stream` use the v1 queued-write pattern (`SessionSaveOutcome` synced/queued).
- **Requirement:** a session interrupted after training end (during gate/cooldown) is still scored and saved (BR-2-20); an abandoned transition gate finalizes after timeout, never hangs.

## Data volume
- Per-second `hr_stream` ≈ 2100 records/Continuous, 2220/HIIT incl. cooldown, each now carrying a `phase` tag + optional `phrase_type`/`phrase_time`. Same order of magnitude as v1; stored as a compact encoded blob under the session doc (v1 pattern). No pagination concern at single-user scale.

## Security (Baseline — Full/blocking)
| Rule | P2 | How |
|---|---|---|
| SECURITY-03 no PII/health in logs | **Primary** | HR values, targets, scores, phrase text never console/analytics-logged (BR-2-28). |
| SECURITY-01 encryption | Yes | Sessions/`hr_stream` persist under existing Firebase doc (TLS + at-rest). |
| Own-data rules + consent | Yes | Inherited from Phase 1; no new paths or auth surface. |
| SECURITY-02 / 04 | N/A | No new network surface or secrets. |

## Testability (PBT partial)
- Pure engines isolated for exhaustive/property tests: protocol bpm ranges, off-zone severity around ±5, escalation timing, no-3×-repeat under **seeded RNG**, scorer tier boundaries, briefing 0–4 boundary.
- On-device verification (Watch HR + voice + background workout) required before any TestFlight build, as in v1.

## Usability / accessibility
- **Voice-off fallback:** every `CoachingMessage` has an on-screen text/visual equivalent (§J, v1 pattern) — blocking for the silent-mode path.
- Cooldown steps and the "ready to stretch" gate must be fully operable on-screen without audio.

## Out of scope (later phases)
Progression/assignment load (P3), exercise rendering (P4/P5), export/PDF throughput (P6). None affect Phase 2.
