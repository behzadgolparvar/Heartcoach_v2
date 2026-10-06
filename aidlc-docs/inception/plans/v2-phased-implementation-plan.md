# v2 Phased Implementation Plan — v5 RE-PLAN

**Cycle:** v2 · **Branch:** new_design_Sep_2026 · **Delivery:** incremental, each phase TestFlight-shippable (Q7=A)
**Risk:** High (system-wide redesign) → mitigated by phasing + `main` staying on v1.
**Source:** `hr-coaching-app-full-spec.md` (v5) + `v2-requirements.md` (incl. v5 revision).
**Re-plan reason:** collaborator's v5 spec replaced the single assignment engine with a **4 training-stage program** (Foundation → Level Up → Shape → Maintain), each with its own 60-session / 3-sub-phase (×20) **session-gated ratio progression** and its own unlock questions. This supersedes the old 5-phase plan below the line.

Each **phase = one AI-DLC unit of work**, runs its own Construction stages (Functional Design → NFR → Code Generation → test), and ends at a shippable milestone. Security Baseline is a blocking gate in every phase; PBT (partial) applies to the logic/serialization noted.

---

## Dependency overview

```
P1  Onboarding + Profile + Data model              [DONE]
      │
      ▼
P1b Onboarding v5 deltas (dual experience, Ozempic, stage/counter fields)
      │
      ▼
P2  Foundation protocols + rich coaching + cooldown + scoring
      │
      ▼
P3  Classification resolution + session-gated progression + relapse/minimum
      │
      ▼
P4  Level Up (bodyweight leg phases woven into blocks/rounds)
      │
      ▼
P5  Shape (Option A/B daily choice + muscle-group selection + weight banks)
      │
      ▼
P6  Milestones + reminders + export + client PDF
```
Stage 4 (**Maintain**) is undesigned in v5 → out of scope this cycle.

---

## Phase 1 — Onboarding, Profile & Data Model  *(DONE — shipped)*
Consent-first onboarding, expanded v2 profile, new Firestore `v2profile`, reused Karvonen zones, full re-onboarding routing. 46/46 tests green, app builds. *Completed before v5 adoption.*

## Phase 1b — Onboarding v5 deltas  *(small, shippable)*
**Delivers:** the onboarding/profile changes v5 introduced, so downstream stages have the data they need.
- **Dual experience**: Q1 training-history (authoritative) + Q2 self-select → resolution matrix → stored `resolvedExperience`
- **Ozempic/GLP-1 = Yes → auto-Beginner override** (editable, informational popup)
- Data model: `trainingStage` (foundation/levelUp/shape/maintain), **per-stage session counter**, sub-phase index; placeholders for Option A/B daily selection + muscle-group priority (filled in P5)
- Make **joint/health history active** (feeds Level Up exercise exclusion later)
**Depends on:** Phase 1
**Construction:** Functional Design (experience matrix + stage/counter model), NFR (security re-check), Code Gen
**PBT:** experience-resolution matrix exhaustive; Ozempic override; profile Codable round-trip incl. new fields
**Milestone:** onboarding classifies into a training stage + experience; data model carries stage/counter

## Phase 2 — Foundation Protocols, Coaching, Cooldown & Scoring  *(core value, shippable)*
**Delivers:** the complete Foundation-stage workout experience end-to-end (training stage 1).
- **Foundation Continuous** (7×5-min blocks, progressive %HRR, +30s buffer) + **Foundation HIIT** (15×1/1) — pure HR, no exercises (FR-4)
- Coaching engine v2 (FR-5): priority hierarchy, 15s off-zone / 5s safety, minor/major × low/high + in-zone **phrase pools** (no-3×-repeat), block/round transitions + direction phrases, "N left", **escalation** (HIIT 30s / Cont 60s), **pre-session briefing** (first 4/type *per stage*), voice-off text
- **Mandatory 2-min cooldown stretch** sequence ending every session (FR-6b, §F)
- **Scoring** = % time in target → tier → spoken + visual (FR-6)
- Record `phrase_type`/`phrase_time` into `hr_stream`; safety/edge (FR-9)
- Workout selection = **manual picker** (Continuous / HIIT) until P3 (Q7=A)
**Depends on:** Phase 1b (zones, stage), v1 Watch HR pipeline + voice/haptic (reused)
**Construction:** Functional Design (protocol tables + coaching state machine + cooldown + scoring), NFR, Code Gen
**PBT:** target-zone timeline; phrase-selection rules; no-repeat rotation; score/tier boundaries
**Milestone:** run Foundation Continuous & HIIT with full coaching, cooldown, and scoring (manual pick)
*(Note: the open `phase2-protocols-coaching-functional-design-plan.md` questions still apply — answer them when Phase 2 functional design resumes.)*

## Phase 3 — Classification Resolution & Session-Gated Progression  *(headline, shippable)*
**Delivers:** the app decides today's Foundation session for you and advances you through the stage.
- **Classification → ratio tables** per Beginner/Intermediate/Advanced × mentality (× goal for Beginner)
- **Session-gated progression**: 60 sessions / **3 sub-phases of 20**, counter-driven HIIT:Continuous mix (not month-based)
- **Relapse / re-entry push-back** (FR-3b): 2w→3, 3w→5, 1mo→8, >1mo→reset to sub-phase start
- **Non-negotiable 15-min walk minimum** (FR-12): 8 fast/7 slow fallback, doesn't count toward progression
- Stage-complete → advance to next training stage (gate to P4)
- "Today's assigned session" home replacing the manual picker (manual override optional)
**Depends on:** Phase 1b (stage/counter), Phase 2 (runnable protocols)
**Construction:** Functional Design (ratio tables + gating + relapse rules), NFR, Code Gen
**PBT:** ratio-table math across all profile combos; counter/sub-phase transitions; push-back arithmetic
**Milestone:** Foundation stage is fully auto-driven across its 60 sessions

## Phase 4 — Level Up (training stage 2)  *(shippable)*
**Delivers:** the second training stage — aerobic + **bodyweight leg exercise phases**.
- **Level Up unlock question set** (gated at Foundation completion)
- Leg-exercise phases (plyometric/bodyweight, §G leg bank) **woven into** Continuous blocks / HIIT rounds with synced rep counts; own timelines
- **Health/joint-history exercise exclusion** applied (from P1b)
- Reuse P2 coaching/cooldown/scoring + P3 progression, extended for Level Up ratios
**Depends on:** Phase 2 (coaching/protocols), Phase 3 (progression/stage advance), Phase 1b (joint history)
**Construction:** Functional Design (leg-phase interleave + exclusion), NFR, Code Gen
**PBT:** exercise selection honoring exclusions; rep-count sync; Level Up ratio math
**Milestone:** Level Up runs end-to-end with leg phases and its own 60-session progression

## Phase 5 — Shape (training stage 3)  *(shippable)*
**Delivers:** the third training stage — daily choice + resistance.
- **Shape unlock + per-session questions**; daily **Option A (plyometric) / Option B (weights)** choice
- **Muscle-group selection + priority** (4-2 / 6-5 phase alternation); standing free-weight banks (§G: chest/back/shoulders/arms/abs)
- Shortened-run timelines; **Shape-HIIT special 2-checks-per-50s** feedback timing
**Depends on:** Phase 4 (stage framework + exercise interleave)
**Construction:** Functional Design (Option A/B flow + muscle-priority rotation + weight banks + special timing), NFR, Code Gen
**PBT:** muscle-group rotation (4-2/6-5); Option A/B selection; Shape-HIIT check cadence
**Milestone:** Shape runs end-to-end with daily option + muscle-group targeting

## Phase 6 — Milestones, Reminders, Export & Client PDF  *(engagement + research, shippable)*
**Delivers:** outcome tracking, retention nudges, research pipeline, client deliverable.
- **Biweekly milestones** (FR-10): morning **RHR + weight**; weight-entry gating (Day 2 missed → blocked until logged)
- **Local push reminders** (FR-7) from schedule; auto-adjust on preference edits; content = today's session + duration
- Per-session **CSV/XLSX export** to Firebase Storage (FR-8), incl. `phrase_type`/`phrase_time`, hidden from user
- **Per-stage client-facing session-plan PDF** (FR-11), indexed by session #
**Depends on:** Phase 1b (schedule/profile), Phase 2+ (hr_stream, sessions), Phase 3+ (stage/session index)
**Construction:** Functional Design (milestone cadence + notification scheduling + export/flatten + PDF layout), NFR (Storage rules, no-PII exposure), Code Gen
**PBT:** hr_stream → CSV row round-trip; milestone-due date math; gating logic
**Milestone:** milestones prompt on schedule, reminders fire, CSVs land in Storage, client PDF generates per stage

---

## Cross-cutting (every phase)
- **Security Baseline (blocking):** encryption in transit/at rest, no PII/health data in logs, Firestore own-data rules, consent gating, secrets never committed.
- **`main` = v1** stays shippable for hotfixes throughout; v2 merges to `main` when ready to release.
- **Testing:** unit + PBT (partial) per phase; on-device Watch/HealthKit verification before each TestFlight milestone.

## Suggested unit sequence
P1 (done) → **P1b → P2 → P3 → P4 → P5 → P6** (strict dependency order). Each training stage (Foundation P2–P3, Level Up P4, Shape P5) is independently shippable once its predecessor lands.

---

## Superseded 5-phase plan (pre-v5, archived)
The earlier plan assumed a single month-based assignment engine and no training stages. It is superseded by the structure above; kept here only for traceability. Key changes: assignment engine → per-stage session-gated ratio progression (P3); Fartlek already removed; added training stages (P4 Level Up, P5 Shape), cooldown stretch, milestones, client PDF, non-negotiable minimum, relapse push-back; Maintain deferred.
