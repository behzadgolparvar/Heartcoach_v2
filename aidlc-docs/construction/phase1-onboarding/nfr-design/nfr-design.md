# Phase 1 — NFR Design

How the NFRs map onto concrete components/patterns. Most reuse v1 mechanisms.

## Security patterns
- **Consent gate:** `OnboardingContainerView` renders `ConsentView` first and holds an in-memory draft only; the `save()` path is unreachable until `healthDataConsent && remindersConsent`. No Firestore write, no persistence, before that.
- **No-PII logging:** persistence and view models use no `print`/logging of field values; any diagnostic logs carry only non-sensitive status (mirrors the existing SECURITY-03 discipline).
- **Own-data access:** all reads/writes target `users/{uid}` under the authenticated session; enforced by the published Firestore rules.
- **Encryption:** provider-managed (Firestore TLS + at-rest) — no app action needed.

## Reliability / availability patterns
- **Offline-tolerant save:** reuse the v1 `FirestoreService` write path (attempt-with-timeout → queue → retry; honest "saved / will sync" status).
- **Draft isolation:** draft lives in `OnboardingViewModel`; abandoning the flow persists nothing.
- **HealthKit degradation:** RHR prefill is best-effort; failure/empty falls back to manual entry without error.

## Performance patterns
- Derived values (unit conversions, BMI, zones, mentality-lean) computed synchronously (O(1)); zones/lean recompute only on input change.
- HealthKit fetch is `async`, off the main actor for the query, result applied on `@MainActor`.
- One batched document write on Save.

## Maintainability / testability patterns
- **Pure core in `HeartRateCoachCore`:** `UnitConverter`, `BMI`, `MentalityLean`, and the extended `UserProfile`/enums are pure, dependency-free → unit- and property-testable.
- **Protocol-backed services** (Firebase, HealthKit) reused so onboarding VM is testable with mocks (as v1).

## Accessibility patterns
- VoiceOver labels + `accessibilityIdentifier`s on every field (also enables UI tests); Dynamic Type; keyboard dismissal via reused `hideKeyboardOnTap()`.

## Infrastructure note
**Infrastructure Design will be SKIPPED** — no new infrastructure: Firebase (Auth/Firestore), HealthKit, and the app targets already exist from v1. Only application code + Firestore document shape change.
