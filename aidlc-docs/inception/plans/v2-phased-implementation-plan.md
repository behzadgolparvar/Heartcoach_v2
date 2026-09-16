# v2 Phased Implementation Plan

**Cycle:** v2 · **Branch:** new_design_Sep_2026 · **Delivery:** incremental, each phase TestFlight-shippable (Q7=A)
**Risk:** High (system-wide redesign) → mitigated by phasing + `main` staying on v1.
**Source:** `v2-requirements.md` (FR-1…FR-9), the two specs, and the v2 decisions.

Each **phase = one AI-DLC unit of work**, runs its own Construction stages (Functional Design → NFR → Code Generation → test), and ends at a shippable milestone. Security Baseline is a blocking gate in every phase; PBT (partial) applies to the logic/serialization noted.

---

## Dependency overview

```
Phase 1 (Onboarding + Profile + Data model)
        │
        ▼
Phase 2 (Redesigned Protocols + Rich Coaching)
        │
        ├──────────────▼
        │        Phase 3 (Assignment + Progression engine)   ← headline (Q3=A)
        ▼
Phase 4 (Scoring + Summary + Safety/Edge cases)
        │
        ▼
Phase 5 (Reminders + Research export)
```
Phase 3 (the auto-assignment headline) is delivered at the **earliest feasible point** — it needs the new profile fields (P1) *and* runnable protocols (P2), so it lands right after them.

---

## Phase 1 — Onboarding, Profile & Data Model  *(foundation, shippable)*
**Delivers:** the new consent-first onboarding and expanded, personalized profile — reusing v1 auth and (temporarily) the v1 workout engine so the app stays usable.
- Consent-first flow → 7 sections in spec order (FR-1)
- Units toggles (lbs/kg, cm/in, store both) + auto BMI; RHR guided entry + 40–100 warning; Max HR auto/optional-manual
- All health-history fields incl. optional section (Q5=A): chronic conditions, HR meds, smoking, joint, Ozempic, occupation, fitness experience, mentality (×3), goals (multi), scheduling, device
- **New Firestore schema** (FR-8): `profile` / `physiology` / `hr_zones` / `settings`; keep sessions on v1 shape for now
- Karvonen zones **reused** from v1
**Depends on:** v1 auth, HealthKit (reused)
**Construction:** Functional Design (data model + form logic), NFR (security: consent gating, no-PII-logs, own-data rules), Code Gen
**PBT:** unit-conversion + BMI + zone calc round-trips
**Milestone:** user completes redesigned onboarding, sees personalized zones; workouts still run on v1 engine

## Phase 2 — Redesigned Protocols & Rich Coaching  *(core value, shippable)*
**Delivers:** the new workout experience — the heart of v2.
- **Continuous** 7-block progressive table; **HIIT** 15-round / 6-true-block table; **Fartlek removed** (FR-4)
- Coaching engine rebuild (FR-5): priority hierarchy, 15s off-zone / 5s safety cadence, minor/major × low/high + in-zone **phrase pools** (5–6, no-3×-repeat), block-transition + direction phrases, "N left" reminders, **escalation** (HIIT 30s / Cont 60s), **pre-session briefing** (mandatory first 4/type), voice-off text equivalents
- Record `phrase_type` + `phrase_time` into `hr_stream`
**Depends on:** Phase 1 (zones), v1 Watch HR pipeline + voice/haptic (reused)
**Construction:** Functional Design (protocol tables + coaching state machine), NFR, Code Gen
**PBT:** phase/target-zone timeline, phrase-selection rules, no-repeat rotation
**Milestone:** run the redesigned Continuous & HIIT end-to-end with the new coaching (manual pick)

## Phase 3 — Assignment & Progression Engine  *(headline — Q3=A, shippable)*
**Delivers:** the app decides today's workout for you.
- Assignment logic (full-spec §2): experience + goals + mentality; beginner progression ratios by month × mentality; intermediate/advanced leans
- **Progression tracking**: per-type session history, month buckets, ratio state
- "Today's assigned session" home screen replacing the manual picker (manual override optional)
**Depends on:** Phase 1 (profile fields) + Phase 2 (runnable protocols)
**Construction:** Functional Design (assignment + progression rules), NFR, Code Gen
**PBT:** assignment engine (all profile combos → valid, spec-matching assignments), progression ratio math
**Milestone:** personalized auto-assignment drives each session

## Phase 4 — Scoring, Summary & Safety/Edge Cases  *(lifecycle polish, shippable)*
**Delivers:** a complete, robust session lifecycle.
- **Score** = % time in zone → tiers; spoken closing + visual summary (FR-6)
- Safety/edge (FR-9): 20s dropout (resume-in-place, gap flag, safety-off warning); pause/resume 15-min prompt (Continue/Finish/More, 3 snoozes); cancel rule (≥20 scored / <20 discarded); **elevated-HR walk-fallback** (`walk_fallback`, excluded from progression)
**Depends on:** Phase 2 (session engine), Phase 3 (progression exclusion for fallback)
**Construction:** Functional Design (scoring + state machines), NFR, Code Gen
**PBT:** score/tier boundaries, pause/dropout state transitions
**Milestone:** every session scored + edge cases handled gracefully

## Phase 5 — Reminders & Research Export  *(engagement + research, shippable)*
**Delivers:** retention nudges and the research data pipeline.
- **Local push notifications** from schedule (FR-7), auto-adjust on preference edits, content = today's session + duration
- Per-session **CSV/XLSX export** to Firebase Storage (FR-8), incl. `phrase_type`/`phrase_time`, hidden from user
**Depends on:** Phase 1 (schedule), Phase 2 (hr_stream fields)
**Construction:** Functional Design (notification scheduling + export/flatten), NFR (Storage access rules, no-PII exposure), Code Gen
**PBT:** hr_stream → CSV row mapping round-trip
**Milestone:** reminders fire on schedule; research CSVs land in Storage

---

## Cross-cutting (every phase)
- **Security Baseline (blocking):** encryption in transit/at rest, no PII/health data in logs, Firestore own-data rules, consent gating, secrets never committed.
- **Migration:** existing v1 users/data — Phase 1 must read v1 profiles and map to the new schema without data loss (or a clean re-onboard path).
- **`main` = v1** stays shippable for hotfixes throughout; v2 merges to `main` when a phase (or the whole cycle) is ready to release.
- **Testing:** unit + PBT (partial) per phase; on-device Watch/HealthKit verification before each TestFlight milestone.

## Suggested unit sequence
P1 → P2 → P3 → P4 → P5 (strict dependency order; P4 and P5 could partially overlap once P2/P3 land).
