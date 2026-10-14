# Phase 1 — NFR Requirements

No open questions: the technology stack was decided in v2 Requirements (Q1=A, native) and security is fixed by the Security Baseline extension. NFRs below are confirmed/inherited.

## Tech stack (confirmed — reuse v1)
- **UI/logic:** Swift 5.9, SwiftUI, iOS 17+; `@Observable` view models, MVVM as v1.
- **Persistence:** Firebase Firestore (storage only; all logic local). Offline-tolerant write pattern reused from v1.
- **Health:** HealthKit (resting-HR read) reused.
- **Core package:** `HeartRateCoachCore` (Karvonen `ZoneCalculator` reused; new profile/enums added here for testability).

## Security (Baseline — blocking)
- **SECURITY-01** Encryption in transit/at rest — Firestore TLS + managed encryption (provider default). ✅
- **SECURITY-03** No secrets/PII/health data in logs — enforced in onboarding + persistence (BR-10). ✅
- **Own-data access** — Firestore rules already restrict `users/{uid}` to the authenticated user (published). ✅
- **Consent gating** — no collection/write before both consents accepted (BR-1). ✅
- Secrets (`GoogleService-Info.plist`) remain git-ignored. ✅
- **SECURITY-02/04** (network intermediaries, web headers) — **N/A** (native iOS app, no web endpoints).

## Performance
- Onboarding is lightweight; live BMI/zone/lean calc are O(1) — no perf concern.
- HealthKit RHR fetch is async, must not block the UI; failure degrades to manual entry.
- Single Firestore document write on Save.

## Availability / Reliability
- Offline at Save → queue + retry (reused v1 pattern); "saved, will sync" messaging, never a hard block.
- Consent-gated draft is in-memory only; abandoning leaves no orphan data.

## Usability / Accessibility
- VoiceOver labels on all fields; Dynamic Type; sufficient contrast (dark theme).
- Numeric fields dismiss the keyboard via tap/swipe (reused `hideKeyboardOnTap()` / `dismissableKeyboard()`).
- Clear inline validation and required-field gating.

## Maintainability / Testability
- Profile model + conversions + mentality-lean + zones are pure functions in the core package.
- **PBT (partial)** targets: unit conversions, BMI, zone calc, mentality-lean, and profile encode/decode round-trip.
