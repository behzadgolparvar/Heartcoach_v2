# Phase 1b — NFR Requirements (Onboarding v5 deltas)

**Note:** P1b is a data-model + onboarding-logic delta on the Phase 1 foundation. Tech stack, transport, auth, and storage are already fixed and reused — so **no new NFR questions were required** (nothing ambiguous). This document records which NFRs are inherited unchanged and the few that the delta touches.

## Security (Baseline — Full/blocking)
| Rule | Applies to P1b? | How satisfied |
|---|---|---|
| SECURITY-01 encryption in transit/at rest | Yes (new fields stored) | New fields (`q1TrainingHistory`, `q2SelfSelect`, `classificationMismatch`, `program`) persist in the same Firestore `users/{uid}.v2profile` doc — Firebase TLS + at-rest encryption, unchanged. |
| SECURITY-03 no PII/health data in logs | **Yes (primary)** | Classification inputs/outputs + Ozempic flag are health data: BR-1b-10 forbids console/analytics logging. No `print`/logger calls on these fields. |
| Own-data Firestore rules | Yes | Inherited Phase 1 rules (auth + `request.auth.uid == uid`); no new collections/paths. |
| Consent gating | Yes | Inherited; experience/Ozempic captured only after both consents (Phase 1 gate unchanged). |
| SECURITY-02 (network/API hardening) | N/A | No new network surface. |
| SECURITY-04 (secrets management) | N/A | No new secrets; `GoogleService-Info.plist` remains gitignored. |

## Performance
- Classification resolution is a pure in-memory function (≤24 branch evaluations) — sub-millisecond; no perf concern.
- No new network round-trips; new fields ride the existing single profile read/write.
- **Requirement:** no measurable change to onboarding-save or app-launch-routing latency vs Phase 1.

## Reliability / Availability
- Inherits Phase 1 offline-tolerant write pattern (no change).
- Migration (Q8=B): a pre-v5 profile that fails the v5-complete check routes to re-onboarding rather than crashing or showing a half-populated profile — a deterministic, safe degradation. `.loadError` retry path preserved for transient load failures.
- **Requirement:** decoding a Phase-1 (pre-v5) profile must never throw; it must decode to a value that reports `isV5Complete == false`.

## Maintainability / Testability
- `ExperienceResolver` is pure and isolated → PBT (partial): exhaustive over 24 input combos.
- `StageProgress.subPhase`/`isStageComplete` pure → PBT over 0…60.
- `UserProfileV2` Codable round-trip incl. new fields + a pre-v5 fixture → asserts `isV5Complete == false`.
- No change to CI/build tooling (xcodegen + app test target; core SwiftCheck target still excluded per Phase 1 note).

## Usability
- Q1 honesty-framing prompt and Q2 plain-language definitions (Q1 result hidden) are UI-copy requirements carried into NFR Design / Code Gen.
- Ozempic popup copy is fixed verbatim (BR-1b-4); informational, non-blocking, confirm-to-continue.

## Scalability
- No change. Per-user document; no aggregate/query load introduced.

## Explicitly out of scope (deferred phases)
Progression math load (P3), exercise-bank storage (P4/P5), export/PDF I/O performance (P6). None affect P1b.
