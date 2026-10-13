# Build & Test Summary — HeartCoach v5

**Branch:** `new_design_Sep_2026`. All 6 feature phases (P1/P1b, P2–P6) complete; **134 unit tests green**; core + app build on simulator; SECURITY-03 grep clean across all phases.

## Instruction set (this folder)
- `build-instructions.md` — SPM + xcodegen + simulator/device build, TestFlight.
- `unit-test-instructions.md` — full-suite run + per-phase coverage map.
- `integration-test-instructions.md` — on-device E2E per stage + Phase 6 systems + safety/edge.
- `performance-test-instructions.md` — live-session memory/battery + one-off ops.
- `backlog.md` — the open device/deferred/owner/collaborator items (the single source of truth for what's left).

## State of the code
| Area | Status |
|---|---|
| Onboarding + classification (P1/P1b) | ✅ built, tested |
| Foundation protocols + coaching + cooldown + scoring (P2) | ✅ built, tested |
| Progression + assignment + relapse + minimum (P3) | ✅ built, tested |
| Level Up + Shape (P4/P5) | ✅ built, tested |
| Milestones + reminders + export + PDF (P6) | ✅ built, tested |
| Advanced §J safety | ⏳ backlog A (deferred from P2) |
| Coaching refinements (per-rep count, Shape-HIIT tuning) | ⏳ backlog B |
| On-device verification | ⏳ backlog C |
| Owner deploy (Storage rules) | ⏳ backlog D |
| Collaborator confirmations (banks/tags, Q3) | ⏳ backlog E |

## Recommended order for the device pass
1. Owner: publish Storage rules (D) so export can be verified.
2. Wire §J safety (A) — overlaps with P3 plumbing; keeps the app shippable.
3. Device E2E (C) across the three stages; tune coaching (B) from what you observe.
4. Internal TestFlight (testers re-onboard once, Q8=B); gather collaborator confirmations (E).

## Security
SECURITY-01 (encryption) + SECURITY-03 (no PII/health in logs or notifications) satisfied in code. SECURITY-02 (own-data) — Firestore rules live; **Storage rules pending owner deploy (D)**. Consent gating from onboarding intact.
