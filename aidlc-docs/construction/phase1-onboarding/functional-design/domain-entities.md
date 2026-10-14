# Phase 1 — Domain Entities

Technology-agnostic domain model for the v2 profile + onboarding. Maps to Firestore per full-spec §5.1. Units stored in **both** systems; display uses the user's chosen unit.

## Profile
| Field | Type | Notes |
|---|---|---|
| age | Int | required; 15–100 |
| gender | enum `male \| female \| preferNotToSay` | required |
| weightKg / weightLbs | Double? | optional; both stored, converted from whichever the user entered |
| heightCm / heightIn | Double? | optional; both stored |
| bmi | Double? | derived; present only when height+weight present |
| unitsPreference | enum `metric \| imperial` | default from locale (Q4=A) |

## Physiology
| Field | Type | Notes |
|---|---|---|
| restingHR | Int | required; HealthKit-prefilled + editable (Q5=A); 40–100 confirm-warning |
| maxHR | Int | default `220 − age`; optional manual override; must be > restingHR |

## HRZones  *(reused from v1 — Karvonen)*
`zone1…zone5 : { min: Int, max: Int }` computed from age + restingHR (+ maxHR). Recomputed when any input changes.

## Settings
| Field | Type | Notes |
|---|---|---|
| goals | Set<enum `fastWeightLoss \| routine \| cardioFitness`> | required; ≥1 |
| fitnessExperience | enum `beginner \| intermediate \| advanced` | required (drives assignment) |
| mentality | Mentality (below) | required |

## Mentality
| Field | Type | Notes |
|---|---|---|
| motivationDriver | enum `process \| outcome` | required |
| missedResponse | enum `habit \| goal` | required |
| routinePreference | enum `fixed \| variety` | required |
| derivedLean | enum `process \| outcome \| mixed` | **computed** (Q2=A majority rule) — see business-rules |

## HealthHistory  *(optional section — Q3=A / Q5 spec: stored, mostly future-use)*
| Field | Type |
|---|---|
| chronicConditions | Set<enum `t2dm \| cvd \| hypertension \| none`> + otherText? |
| hrMedications | Set<enum `betaBlockers \| other \| none`> |
| onAntiObesityTherapy | Bool |
| smokingStatus | enum `never \| former \| current` |
| jointIssues | Set<enum `knees \| back \| hips \| ankles \| none`> + otherText? |
| occupationActivity | enum `sedentary \| light \| active \| veryActive` |

## Schedule
| Field | Type | Notes |
|---|---|---|
| sessionLengthMin | Int | required |
| frequencyPerWeek | Int | required |
| preferredDays | Set<Weekday> | optional |
| preferredTimeOfDay | enum `morning \| afternoon \| evening` | optional |
| reminderMethod | enum `call \| text` | captured per spec; **delivery is push** this cycle (Q4=A reminders) |

## Device
| Field | Type |
|---|---|
| wearable | enum `appleWatch \| none` |
| existingTrackingApp | Set<enum `strava \| other \| none`> |

## Consent
| Field | Type | Notes |
|---|---|---|
| healthDataConsent | Bool | **required true before any data is collected/stored** |
| remindersConsent | Bool | required |
| consentedAt | Date | timestamp |
| consentVersion | String | for future policy revisions |

## Firestore mapping (§5.1)
```
users/{uid}
  profile:     { age, gender, weightKg, weightLbs, heightCm, heightIn, bmi, units }
  physiology:  { resting_hr, max_hr }
  hr_zones:    { zone1..zone5: {min,max} }
  settings:    { goals[], fitness_experience, mentality{...}, mentality_lean }
  health:      { conditions[], hr_meds[], anti_obesity, smoking, joints[], occupation }   // optional
  schedule:    { session_len_min, freq_per_week, days[], time_of_day, reminder_method }
  device:      { wearable, tracking_apps[] }
  consent:     { health_data, reminders, consented_at, version }
  onboarding:  { v2_completed: Bool, completed_at }
```
