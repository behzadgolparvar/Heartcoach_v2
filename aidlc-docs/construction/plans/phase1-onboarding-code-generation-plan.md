# Phase 1 — Code Generation Plan (single source of truth)

**Unit:** Onboarding + Data Model · **Type:** brownfield (extend existing native Swift app) · **Branch:** new_design_Sep_2026
**Design source:** `construction/phase1-onboarding/functional-design/*`, `nfr-*`
**Rule:** modify existing files where sensible; keep v1 workout engine runnable (this phase does NOT touch protocols/coaching).

## Unit context
- **Delivers:** new consent-first onboarding + expanded profile + new Firestore schema; reused Karvonen zones; full re-onboarding routing (BR-9).
- **Depends on:** v1 Auth, HealthKit, `HeartRateCoachCore`, `FirestoreService` (all reused/extended).
- **Milestone:** user completes v2 onboarding, sees personalized zones; workouts still run on the v1 engine.

---

## Step 1 — Core domain models (`HeartRateCoachCore`)  [x]
Add/extend pure models (source of truth, testable):
- [ ] `Models/Gender.swift` (`male/female/preferNotToSay`)
- [ ] `Models/FitnessExperience.swift` (`beginner/intermediate/advanced`)
- [ ] Extend `Goal` → new cases `fastWeightLoss/routine/cardioFitness` and support **multi-select** (Set) — keep v1 decode tolerant
- [ ] `Models/Mentality.swift` (3 enums + `MentalityLean` + `derivedLean` via majority rule, BR-7)
- [ ] `Models/HealthHistory.swift` (conditions, meds, smoking, joints, occupation, anti-obesity)
- [ ] `Models/Schedule.swift`, `Models/DeviceInfo.swift`, `Models/Consent.swift`
- [ ] Rework `Models/UserProfile.swift` → v2 superset (profile/physiology/settings/health/schedule/device/consent + `unitsPreference`, `maxHR`, `v2Completed`)

## Step 2 — Core pure logic (`HeartRateCoachCore`)  [x]
- [ ] `Units/UnitConverter.swift` (kg↔lbs, cm↔in) (BR-2)
- [ ] `Units/BMI.swift` (BR-3)
- [ ] `MentalityLean` derivation (BR-7) — in `Mentality.swift`
- [ ] Confirm `ZoneCalculator` unchanged (reused)

## Step 3 — Core unit + property tests  [x] (relocated to app test target; core SwiftCheck target broken under Xcode 26 — flagged for Build&Test)
- [ ] `Tests/…/UnitConverterTests.swift`, `BMITests.swift`, `MentalityLeanTests.swift`
- [ ] **PBT (partial):** conversion round-trips (lbs→kg→lbs), BMI monotonicity, mentality-lean exhaustive over all 8 combos, `UserProfile` Codable round-trip

## Step 4 — Persistence (app `FirestoreService`)  [x]
- [ ] Extend `FirebaseServiceProtocol`: `saveProfile(_ profile:)` / `loadProfile()` to the **new §5.1 document shape** (profile/physiology/hr_zones/settings/health/schedule/device/consent/onboarding)
- [ ] Encode/decode all new sections; tolerant of missing optional sections
- [ ] Keep offline-tolerant write pattern (reused)
- [ ] Update `MockFirebaseService` accordingly

## Step 5 — Onboarding view model (app)  [x]
- [ ] Replace `ViewModels/OnboardingViewModel.swift` with v2: in-memory draft for all sections, per-section `isValid`, computed `bmi/zones/mentalityLean`, HealthKit RHR prefill, `save()` (derived-value pipeline → Firestore → `v2Completed=true`)
- [ ] Consent gating (no save path until both consents) (BR-1)

## Step 6 — Shared UI components (app `Views/Components`)  [x]
- [ ] `MeasurementField.swift` (value + unit toggle, both stored)
- [ ] `ProgressDots.swift`, `SelectCard.swift`, `MultiSelectCard.swift`
- [ ] Reuse `hideKeyboardOnTap()`, `dismissableKeyboard()`, `PrimaryButtonStyle`, zone rows

## Step 7 — Onboarding screens (app `Views/Onboarding`)  [x]
- [ ] `OnboardingContainerView.swift` (paging + progress + gating)
- [ ] `ConsentView`, `DemographicsHealthView` (incl. collapsible optional health section), `SchedulingView`, `MentalityView`, `EquipmentView`, `GoalsView`, `DeviceView`, `ZonesPreviewView` (reuse v1 zone rows)
- [ ] Remove/replace superseded v1 onboarding views (`PhysiologicalDataView`, `OptionalDetailsView`, `PreferencesView`, `ZonePreviewView`) — keep any reused bits

## Step 8 — Routing & migration (BR-9)  [x]
- [ ] `AuthViewModel`: route on `onboarding.v2_completed` (signed-in & completed → main; else → v2 onboarding); preserve `.loadError` retry
- [ ] Confirm v1 workout **sessions/History** untouched (only profile reshaped)

## Step 9 — Consumer updates (keep app running)  [x]
- [ ] Update `HomeViewModel`, `SettingsViewModel`, `WorkoutSummary`, `AppContainer` wiring, and anything referencing the old `UserProfile`/`Goal` shape so the app compiles and the v1 workout flow still works with the new profile
- [ ] `SettingsView`: edit the v2 profile fields (extend existing)

## Step 10 — Build, test, verify  [x]
- [ ] `xcodegen generate` (new files), build iOS + core, run full test suite (existing + new)
- [ ] Fix regressions; confirm v1 workout still runs on device path
- [ ] Code summary in `construction/phase1-onboarding/code/` (markdown)

---

### Scope estimate
~10 steps, ~25–30 files (many new, several modified). Largest risks: the `UserProfile`/`Goal` reshape rippling into v1 consumers (Step 9), and Firestore encode/decode of the new schema. Delivered so the app still builds and v1 workouts run at every checkpoint.

### Story/requirements traceability
FR-1 (onboarding), FR-2 (zones reuse), FR-8 (schema) — Phase 1 of `v2-phased-implementation-plan.md`. Security: BR-1 consent gate, BR-10 no-PII logs.
