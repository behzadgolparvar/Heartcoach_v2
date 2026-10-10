# Phase 3 — Business Rules (Progression & Assignment)

`BR-3-*` namespace. All pure/deterministic and PBT-targetable unless noted.

## Track + ratio resolution
- **BR-3-1 (track, Q2=A):** `resolvedExperience == .beginner` → `goals.contains(.fastWeightLoss) ? .beginnerFastWeightLoss : .beginnerRoutineCardio`. `.intermediate`/`.advanced` → their track regardless of goals.
- **BR-3-2 (sub-phase):** `subPhase = min(2, sessionsCompleted / 20)` (reuses `StageProgress`).
- **BR-3-3 (ratio lookup):** `ProgressionTables[track][mentalityLean][subPhase]` from §B. Routine/Cardio has no ratio.

## Assignment (Q1=A, Q3=A)
- **BR-3-4 (today's type):**
  - Ratio tracks (FWL / Intermediate / Advanced): expand `ratio.cycle` (HIIT front-loaded), index by `pos = (sessionsCompleted % 20) % cycle.count` → `cycle[pos]`.
  - `.beginnerRoutineCardio`: `mentalityLean == .outcome` → HIIT when `(sessionsCompleted % 4) == 0` else Continuous; `.process`/`.mixed` → Continuous always.
  - Assignment is for session number `sessionsCompleted + 1`.

## Advancement (Q4=A)
- **BR-3-5 (count a session):** increment `sessionsCompleted` (clamped ≤60) and stamp `lastCountedSessionDate = completionDate` **iff** the session is a scored training session (`sessionFlag` ∈ {continuous, hiit}) that met the ≥20-min rule. Exclude `minimum_walk`, `walk_fallback`, and <20-min discards. `cooldownSkipped` still counts.
- **BR-3-6 (override counts, Q9):** a manually chosen Foundation session (override of the assigned type) counts exactly like an assigned one (BR-3-5). Because assignment is counter-indexed (BR-3-4), an override never corrupts future assignments — the next session is assigned from the incremented counter.

## Relapse / re-entry (§C, Q5=B — spec-literal)
- **BR-3-7 (gap → band):** gap = days between `lastCountedSessionDate` and now.
  ≤7 → none · 8–14 (≈2w) → −3 · 15–21 (≈3w) → −5 · 22–30 (≈1mo) → −8 · >30 → reset.
  (Band thresholds use the spec's week/month labels; exact day cut-offs fixed here for determinism.)
- **BR-3-8 (apply, Q5=B):** push-back = `sessionsCompleted = max(0, sessionsCompleted − N)` — **plain subtraction, may cross sub-phase boundaries**. `reset` → `sessionsCompleted = 0` (Sub-Phase 1, start of stage). Applied **once per gap**: after applying, set `lastCountedSessionDate = now` so re-opening does not re-penalize. Framing always positive (§C).

## Non-negotiable minimum (§I, Q7=A)
- **BR-3-9 (minimum effects):** completing the 15-min minimum walk stamps `lastCountedSessionDate = now` (resets relapse clock) and **does not** change `sessionsCompleted`. Logged `sessionFlag = "minimum_walk"`, excluded from progression stats.
- **BR-3-10 (trigger):** user-initiated from Home; always available; no auto-nudge in P3 (a push-notification nudge is deferred to P6 / FR-7).

## Stage completion (Q8=A)
- **BR-3-11 (complete):** at `sessionsCompleted == 60`, `isStageComplete = true`; assignment keeps serving Sub-Phase 3 (subPhase clamped at 2); the UI shows "Foundation complete — Level Up coming soon". No auto-advance to Level Up (that is P4: set `currentStage = .levelUp` + §E unlock + fresh `StageProgress`).

## Security (inherited, blocking)
- **BR-3-12:** progression values, dates, and assignments are user data — never console/analytics-logged (SECURITY-03). All new state persists under the existing own-data `users/{uid}.v2profile` document; no new auth surface.
