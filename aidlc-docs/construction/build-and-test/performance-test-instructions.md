# Performance Test Instructions — HeartCoach v5

Logic is lightweight; the real constraints are the long live session and battery. Spot-check on device.

## Real-time session
- A full ~37-min session runs a 5s tick (safety) + 15s coaching (or 2/50s Shape-HIIT). Confirm:
  - No UI jank or audio lag across the session; coaching fires on time.
  - **No memory growth** over the session (Instruments → Allocations): the tick is allocation-light; `hr_stream` grows ~1 record/5s (~450 records/session) — expected, bounded.
  - Battery: a full session on Watch + iPhone is comparable to v1 (background workout session).

## One-off operations
- **Protocol build / exercise selection / session-plan projection:** instantaneous (pure, small inputs).
- **PDF render (60 rows):** should complete well under a second; runs off the main thread with a progress affordance.
- **CSV build + Storage upload:** off the session-save critical path; confirm save/summary UI is not blocked by upload latency or failure.

## Data volume
- `hr_stream` per session is small; Firestore doc well within limits. Storage CSVs accumulate under `users/{uid}/exports/` — monitor only if many sessions.

## Acceptance
- No added latency to session save or app launch vs v1.
- PDF/export never block the UI; notifications schedule without noticeable delay.
