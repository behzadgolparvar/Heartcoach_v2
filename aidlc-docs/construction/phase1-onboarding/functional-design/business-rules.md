# Phase 1 — Business Rules

## BR-1 Consent gating (Security-blocking)
- The **Consent** screen is shown first. **No profile/health data is collected, held, or written** until `healthDataConsent == true` AND `remindersConsent == true`.
- Consent stored with `consentedAt` + `consentVersion`.

## BR-2 Units conversion & storage
- Store **both** systems regardless of entry unit:
  - `kg = lbs × 0.45359237`; `lbs = kg ÷ 0.45359237`
  - `cm = in × 2.54`; `in = cm ÷ 2.54`
- Round display to 1 decimal; store full precision.
- Default `unitsPreference` from device locale (US → imperial, else metric); user can toggle any time.

## BR-3 BMI
- `bmi = weightKg ÷ (heightM)²`, `heightM = heightCm ÷ 100`.
- Computed live when **both** height and weight are present; otherwise BMI is nil (not shown). Never user-entered.

## BR-4 Resting HR
- On the Physiology step, **auto-fetch** the latest resting HR from HealthKit and pre-fill (reuses v1 `fetchRestingHeartRate`). Field remains editable.
- If value < 40 or > 100 → show a **confirm-value warning** (non-blocking; user confirms).
- RHR is **required** to finish onboarding.

## BR-5 Max HR
- Default `maxHR = 220 − age`. Optional manual override.
- Constraint: `maxHR > restingHR` (else validation error).

## BR-6 HR Zones (reused Karvonen)
- `HRR = maxHR − restingHR`; zones at 50/60/70/80/90% of HRR (v1 `ZoneCalculator`).
- Recompute whenever age, restingHR, or maxHR changes.

## BR-7 Mentality lean (Q2=A — majority rule)
- Map each answer to a pole:
  - **outcome-ish:** motivationDriver=outcome, missedResponse=goal, routinePreference=variety
  - **process-ish:** motivationDriver=process, missedResponse=habit, routinePreference=fixed
- Count the 3:
  - **3–0** → `outcome` or `process` (strong lean)
  - **2–1** → `mixed`
- Result stored as `mentality.derivedLean`; consumed by the assignment engine (Phase 3).

## BR-8 Required-field gating (Q3=A)
Onboarding cannot complete until ALL present:
- Consent (both), age, gender, restingHR, ≥1 goal, fitnessExperience, all 3 mentality answers, sessionLengthMin, frequencyPerWeek.
- Optional (skippable): height/weight/BMI, all HealthHistory, preferredDays, preferredTimeOfDay, equipment, device.

## BR-9 Migration (Q1=B — full re-onboarding)
- On v2 first launch, **every** user (including v1) is routed through the new onboarding; completion is tracked by a **new** flag `onboarding.v2_completed` (independent of any v1 flag).
- v1 workout **sessions** are preserved (History intact); v1 profile fields are **not** auto-mapped — the user re-enters via the new form (their choice).
- Routing: signed-in AND `v2_completed == true` → main; else → v2 onboarding.

## BR-10 Validation & errors
- Numeric ranges: age 15–100; RHR > 0; frequency 1–7; sessionLength > 0.
- Inline, per-field errors; section can't advance with invalid required fields.
- No health/PII values in logs (Security-blocking).
