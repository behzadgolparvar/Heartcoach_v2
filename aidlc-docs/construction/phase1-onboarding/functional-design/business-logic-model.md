# Phase 1 — Business Logic Model

## Onboarding flow (state machine)
```
[Consent] --both checked--> [Demographics/Health] --> [Scheduling] --> [Mentality]
   |  (blocks all data collection until accepted)          |
   v                                                       v
(cannot proceed)                                    [Equipment] --> [Goals] --> [Device] --> [Review/Save]
```
- Linear, paged; a **progress indicator** (7 dots) shows position.
- Each section validates its **required** fields before "Next" (BR-8). Optional fields never block.
- **Back** preserves entered values (in-memory draft).
- On **Save** (final step): compute derived values (both-unit weights/heights, BMI, maxHR default, zones, mentality lean), write the full document to Firestore (new schema), set `onboarding.v2_completed = true`, route to main.

## Derived-value pipeline (on Save, and live where noted)
1. Units → fill both kg/lbs, cm/in (BR-2)
2. BMI (live when height+weight present) (BR-3)
3. maxHR default = 220−age unless overridden (BR-5)
4. HRZones via Karvonen (BR-6) — also previewed live on a Zones screen before Save
5. mentality.derivedLean via majority rule (BR-7)

## Data flow
- **Inputs:** user form entries; HealthKit resting HR (prefill).
- **Transforms:** conversions, BMI, zones, lean (all local — no server logic).
- **Output/persistence:** single Firestore write per §5.1 mapping; consent recorded first-class.

## Integration points
- **HealthKit:** read resting HR (reuse v1 `HealthKitService.fetchRestingHeartRate`) + existing authorization flow.
- **Firebase Auth:** existing session (reused); onboarding runs for the authenticated user.
- **Firestore:** write profile/physiology/hr_zones/settings/health/schedule/device/consent/onboarding.

## Error scenarios
- **HealthKit RHR unavailable:** field stays empty, user enters manually (no error).
- **Offline at Save:** reuse v1 offline-tolerant write pattern (queue + retry); show "saved, will sync" rather than blocking.
- **Validation failure:** inline errors; Save disabled until required set valid.
- **Partial draft abandoned:** nothing persisted (consent-gated), no orphan data.

## Alternative flows
- **RHR out of 40–100:** confirm-warning, user may proceed after confirming.
- **User declines consent:** cannot proceed; app explains data is required to use HeartCoach.
- **Skip optional section:** allowed; those fields stored as nil/empty.
