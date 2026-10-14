# Phase 1 — Frontend Components (SwiftUI)

## Hierarchy
```
OnboardingContainerView            // owns OnboardingViewModel (draft state), paging, progress dots
├─ ConsentView                     // 2 required checkboxes + policy text; gates everything
├─ DemographicsHealthView
│   ├─ AgeField, GenderPicker
│   ├─ MeasurementField (weight)   // number + unit toggle (kg/lbs)
│   ├─ MeasurementField (height)   // number + unit toggle (cm/in)
│   ├─ BMIReadout                  // live, read-only, shows when height+weight present
│   ├─ RestingHRField              // HealthKit prefill + 40–100 warning
│   ├─ MaxHRField                  // default 220−age, optional override
│   ├─ OccupationPicker, FitnessExperiencePicker
│   └─ OptionalHealthSection (collapsible)   // conditions, meds, Ozempic, smoking, joints
├─ SchedulingView                  // session length, freq/week, days, time-of-day, reminder method
├─ MentalityView                   // 3 single-select cards
├─ EquipmentView                   // facility/equipment multi, home equipment, indoor/outdoor
├─ GoalsView                       // multi-select (fast weight loss / routine / cardio)
├─ DeviceView                      // wearable, existing tracking app
└─ ZonesPreviewView                // reuse v1 zone rows; Save Profile → main
```

## Shared components
- **MeasurementField** — props: `label`, `value: Binding<Double?>`, `unit: Binding<UnitKind>`, `unitOptions`. Emits value + unit; container stores both systems (BR-2). Numeric keyboard + `hideKeyboardOnTap()` (reused).
- **ProgressDots** — props: `total`, `current`.
- **SelectCard / MultiSelectCard** — reusable option rows for pickers/multi-selects.
- **RequirementGate** — disables "Next"/"Save" until the section's required fields validate (BR-8).

## State management
- `OnboardingViewModel` (`@Observable`, `@MainActor`) holds the **in-memory draft** (all sections), exposes computed `bmi`, `zones`, `mentalityLean`, and per-section `isValid`.
- No persistence until final **Save** (consent-gated, BR-1/BR-9).

## User-interaction flows
- Consent → sections in order; Next gated by required validity; Back preserves draft.
- Weight/height: type value, toggle unit; BMI updates live.
- Resting HR: on appear, attempt HealthKit prefill; editable; warning banner if out of range.
- Save: run derived-value pipeline → Firestore write → set `v2_completed` → route to main.

## Validation rules (mirror business-rules)
- Required set per BR-8; numeric ranges per BR-10; `maxHR > restingHR` (BR-5); ≥1 goal.

## API / integration points
- **HealthKitService.fetchRestingHeartRate()** (reused) — RestingHRField prefill.
- **FirebaseService** — one write of the new profile document on Save (offline-tolerant, reused pattern).
- **AuthViewModel routing** — reads `onboarding.v2_completed` to decide onboarding vs main (BR-9).

## Reuse from v1
- `hideKeyboardOnTap()` / swipe-dismiss, `PrimaryButtonStyle`, zone-row views, `HealthKitService`, offline-write + retry, the retry/error patterns.
