# Phase 1 — Code Summary

## Core (`HeartRateCoachCore`)
- Models: `OnboardingEnums`, `Mentality` (+majority-rule `derivedLean`), `ProfileSections` (HealthHistory/Schedule/DeviceInfo/FacilityInfo/Consent), `UserProfileV2` aggregate.
- Logic: `UnitConverter`, `BMI`, `effectiveMaxHR`, `computeZones` (reuses `ZoneCalculator`).

## App
- Persistence: `FirestoreService.saveProfileV2/loadProfileV2` (users/{uid}.v2profile Codable map) + protocol + mock.
- `OnboardingViewModel` (v2): 8-section draft, per-section validity, consent-gated `save()` → `saveProfileV2` → `onComplete`; HealthKit RHR prefill; locale-default units.
- Components: `MeasurementField`, `ProgressDots`, `SelectRow`, `MultiSelectRow`, `OnboardingSection`.
- Screens: `OnboardingContainerView` + 8 sections (Consent, Demographics/Health, Scheduling, Mentality, Equipment, Goals, Device, Zones). Removed v1 onboarding views.
- Routing: `AuthViewModel` routes on `v2Completed` (full re-onboarding, BR-9).
- Consumers: `HomeViewModel` loads v2 profile + derives zones; `SettingsViewModel`/`SettingsView` edit core v2 fields, merge-save.

## Tests (app target, 46/46 green)
`ProfileLogicTests` (11): unit conversions round-trip, BMI monotonic, exhaustive mentality-lean, profile Codable round-trip, effectiveMaxHR, consent. `OnboardingViewModelTests` rewritten for v2 (consent gate, validity, save). Auth/Home tests updated to v2 profile.

## Known follow-up (for Build & Test)
Core package SwiftCheck test target does not compile under Xcode 26 (pre-existing) — Phase 1 tests live in the app target; migrate SwiftCheck→swift-testing or bump version.
