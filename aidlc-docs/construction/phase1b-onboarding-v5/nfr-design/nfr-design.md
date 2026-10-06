# Phase 1b — NFR Design (Onboarding v5 deltas)

How the NFR requirements are realized in the design. P1b is a delta, so this is concise and maps to concrete code placements.

## 1. Security patterns (SECURITY-03 primary)
- **No-health-data-in-logs:** `ExperienceResolver`, `TrainingHistory`, `StageProgress`, `ProgramState`, and the Ozempic flag carry **no** `CustomStringConvertible`/debug logging that emits values. No `print`/`os_log`/analytics call references these fields anywhere. Code Gen checklist item: grep for the new field names in any logging call site → must be zero.
- **At-rest/in-transit (SECURITY-01):** new fields serialize into the existing `users/{uid}.v2profile` Firestore map — inherits Firebase TLS + at-rest encryption; no new storage path.
- **Own-data + consent:** no new Firestore rules; the existing `request.auth.uid == uid` rule already covers the new fields (same document). Consent gate from Phase 1 unchanged — experience/Ozempic captured only post-consent.

## 2. Purity / testability pattern
- **Resolver as pure function** (`static func resolve(...)`) in `HeartRateCoachCore/Engine/` — no Firebase/UIKit import, deterministic, exhaustively testable (24 combos). This is the single place classification is computed; view models and persistence call it, never re-implement the matrix.
- **Derived values** (`subPhase`, `isStageComplete`, `isV5Complete`) are computed properties — no stored duplication, no drift.
- **Write-through invariant** (BR-1b-5) enforced at exactly two call sites: onboarding `save()` and Settings experience/Ozempic edit → both call `ExperienceResolver.resolve` then persist. No other path writes `fitnessExperience`.

## 3. Reliability / migration pattern (Q8=B)
- **Tolerant decode, strict gate:** `UserProfileV2` decodes new fields as optional during decode so a pre-v5 document never throws; a computed `isV5Complete` (all three required fields non-nil) is the gate. Routing: `profile == nil || !isV5Complete → onboarding`.
- **Non-destructive:** re-onboarding overwrites the profile with a complete v5 shape; `program` initialized fresh (Foundation/0). No partial-state persisted.
- **Transient-failure isolation:** load *errors* still route to `.loadError` + retry (unchanged); only *successful loads of incomplete profiles* route to onboarding. The two are distinguished by whether the load threw.

## 4. Performance pattern
- Pure in-memory resolution; no added I/O. New fields piggyback the single existing profile read/write — zero new round-trips. No caching needed.

## 5. Usability pattern
- Q1 honesty-framing prompt + Q2 plain-language definitions rendered in the onboarding experience section; **Q2 view must not read/observe the resolved value or Q1** (keeps Q2 independent per spec §A).
- Ozempic popup: informational modal, confirm-to-continue, fixed copy (BR-1b-4); shown on No→Yes transition and during onboarding when Yes is selected.

## 6. Component/placement map
| Concern | Component | Location |
|---|---|---|
| Classification logic | `ExperienceResolver` | `HeartRateCoachCore/Engine/` |
| New enums/structs | `TrainingHistory`, `TrainingStage`, `StageProgress`, `ProgramState`, `ShapeOption`, `MuscleGroup` | `HeartRateCoachCore/Models/` |
| Profile fields + `isV5Complete` | `UserProfileV2` | `HeartRateCoachCore/Models/UserProfileV2.swift` |
| Persistence (tolerant decode) | `FirestoreService` | app `Firebase/` |
| Onboarding Q1/Q2 + Ozempic popup | onboarding section views + VM | app `Views/Onboarding/`, `OnboardingViewModel` |
| v5-complete routing | `AuthViewModel` | app `ViewModels/` |
| Settings experience/Ozempic edit | `SettingsViewModel` + view | app |

## 7. Infrastructure Design — SKIPPED
No new infrastructure (no new Firebase services, targets, or system frameworks). Consistent with Phase 1.
