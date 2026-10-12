# AI-DLC State Tracking

## Project Information
- **Project Name**: HeartRateCoach
- **Project Type**: Greenfield
- **Start Date**: 2026-05-28T00:00:00Z
- **Current Stage**: CONSTRUCTION - Unit 1 (HeartRateCoachCore) — Functional Design

## Workspace State
- **Existing Code**: No
- **Reverse Engineering Needed**: No
- **Workspace Root**: /Users/behzad/Heartcoach_v2

## Code Location Rules
- **Application Code**: Workspace root (NEVER in aidlc-docs/)
- **Documentation**: aidlc-docs/ only
- **Structure patterns**: See code-generation.md Critical Rules

## Extension Configuration

| Extension | Enabled | Enforcement Mode | Decided At |
|---|---|---|---|
| Security Baseline | Yes | Full — all SECURITY rules blocking | Requirements Analysis |
| Property-Based Testing | Partial | PBT-02, PBT-03, PBT-07, PBT-08, PBT-09 enforced (ZoneCalculator + CoachingEngine only) | Requirements Analysis |

## Stage Progress

### INCEPTION PHASE
- [x] Workspace Detection — COMPLETED (2026-05-28)
- [x] Requirements Analysis — COMPLETED (2026-05-28)
- [x] User Stories — COMPLETED (2026-05-28)
- [x] Workflow Planning — COMPLETED (2026-05-28)
- [x] Application Design — COMPLETED (2026-05-28)
- [x] Units Generation — COMPLETED (2026-06-01)

### CONSTRUCTION PHASE

#### Unit 1 — HeartRateCoachCore (SPM)
- [x] Functional Design — COMPLETED (2026-06-02)
- [x] NFR Requirements — COMPLETED (2026-06-02)
- [x] NFR Design — COMPLETED (2026-06-02)
- [x] Infrastructure Design — SKIPPED (no infrastructure dependencies)
- [x] Code Generation — COMPLETED (2026-06-05)

#### Unit 2 — iPhone Foundation
- [x] Functional Design — COMPLETED (2026-07-14)
- [x] NFR Requirements — COMPLETED (2026-07-14)
- [x] NFR Design — COMPLETED (2026-07-14)
- [x] Infrastructure Design — COMPLETED (2026-07-14)
- [x] Code Generation — COMPLETED (2026-07-15)

#### Unit 3 — iPhone Workout Engine
- [x] Functional Design — COMPLETED (2026-07-15)
- [x] NFR Requirements — COMPLETED (2026-07-15)
- [x] NFR Design — COMPLETED (2026-07-22)
- [x] Infrastructure Design — SKIPPED (no new infrastructure; all frameworks are system-provided)
- [x] Code Generation — COMPLETED (2026-07-22)

#### Unit 4 — Apple Watch App
- [x] Functional Design — COMPLETED (2026-07-22)
- [x] NFR Requirements — COMPLETED (2026-07-22)
- [x] NFR Design — COMPLETED (2026-07-22)
- [x] Infrastructure Design — SKIPPED (no new infrastructure; all frameworks system-provided)
- [x] Code Generation — COMPLETED (2026-07-22)

- [x] Build and Test — COMPLETED (2026-07-22)

### OPERATIONS PHASE
- [ ] Operations — PLACEHOLDER

---

# NEW DESIGN CYCLE (v2) — Sep 2026

## Project Information (v2)
- **Cycle**: v2 — significantly redesigned per collaborator specs
- **Project Type**: Brownfield (existing native Swift/SwiftUI codebase from v1)
- **Branch**: new_design_Sep_2026
- **Start Date**: 2026-09-15T00:00:00Z
- **Current Stage**: INCEPTION - Requirements Analysis (v2)
- **Source specs**: hr-coaching-app-full-spec.md, onboarding-form-spec.md

## Workspace State (v2)
- **Existing Code**: Yes (native Swift/SwiftUI, SPM core, Firebase, HealthKit, WCSession)
- **Reverse Engineering Needed**: Proposed SKIP (codebase already fully understood this session; decision pending user approval in v2-requirements-questions.md)

## Stage Progress (v2)
### INCEPTION PHASE (v2)  ⚠️ SUPERSEDED — see "v2 Stage Progress (updated for v5)" below for current status
- [x] Workspace Detection — COMPLETED (2026-09-15) — brownfield
- [x] Reverse Engineering — SKIPPED (codebase already understood; approved)
- [x] Requirements Analysis — COMPLETED (see v5-updated block below)
- [~] User Stories — SKIPPED (approved)
- [x] Workflow Planning — COMPLETED (re-done for v5)
- [x] Application Design — COMPLETED (folded into phased plan)
- [x] Units Generation — COMPLETED (v2-phased-implementation-plan.md)

## Extension Configuration (v2)

| Extension | Enabled | Enforcement Mode | Decided At |
|---|---|---|---|
| Security Baseline | Yes | Full — all SECURITY rules blocking | v2 Requirements Analysis |
| Property-Based Testing | Partial | Pure functions (zone calc, assignment engine, coaching) + serialization round-trips | v2 Requirements Analysis |

## v2 Requirements Decisions
- Q1 Technology: **Native Swift/SwiftUI** (reuse v1 foundation)
- Q2 Reverse Engineering: **Skip** (codebase already understood)
- Q3 Workout selection: **Full auto-assignment engine** (headline feature) — pulls onboarding + progression tracking forward
- Q4 Reminders: **Push notifications** (local; no Twilio)
- Q5 Health fields: **Collect & store all** (incl. future/clinical-only)
- Q6 Research export: **Include** CSV/Excel to Firebase Storage
- Q7 Delivery: **Incremental phases**, each TestFlight-shippable
- Q8 Security: **Full/blocking**
- Q9 PBT: **Partial**

## v5 RE-PLAN (2026-10-06)
Collaborator supplied `hr-coaching-app-full-spec-v5.md`; user chose "A" (adopt v5 + re-plan). v4 spec archived at `inception/requirements/hr-coaching-app-full-spec.v4.backup.md`; v5 is now canonical `hr-coaching-app-full-spec.md`. This is a `workflow-changes.md` "requirements changed" loop.
- v5 replaces the single month-based assignment engine with a **4 training-stage program** (Foundation → Level Up → Shape → Maintain; Maintain out of scope), each with its own 60-session / 3-sub-phase (×20) session-gated ratio progression + unlock questions.
- Requirements updated: `v2-requirements.md` has a **v5 REVISION** section (FR-1 dual experience + Ozempic override; FR-3 session-gated progression; FR-3b relapse; FR-4 per-stage protocols; FR-6b cooldown; FR-10 milestones; FR-11 client PDF; FR-12 non-negotiable minimum).
- Plan re-structured to **6 phases**: P1 (done) → P1b (onboarding v5 deltas) → P2 (Foundation protocols+coaching+cooldown+scoring) → P3 (classification+session-gated progression+relapse/minimum) → P4 (Level Up) → P5 (Shape) → P6 (milestones+reminders+export+PDF).

## v2 Stage Progress (updated for v5)
- [x] Requirements Analysis — COMPLETED (v2-requirements.md + v5 revision)
- [~] User Stories — SKIPPED (specs + requirements sufficient; user approved skip)
- [x] Workflow Planning — RE-DONE for v5 (6 phases, incremental)
- [x] Units Generation — RE-DONE (v2-phased-implementation-plan.md; 6 units + archived 5-phase plan)
- [x] v5 Re-Plan APPROVED by user (2026-10-06)

### CONSTRUCTION (v2) — Phase 1 (Onboarding + Data Model)
- [x] Functional Design — COMPLETED (2026-09-15)
- [x] NFR Requirements — COMPLETED (2026-09-15)
- [x] NFR Design — COMPLETED (2026-09-15)
- [x] Infrastructure Design — SKIPPED (no new infra; Firebase/HealthKit/targets reused)
- [x] Code Generation — COMPLETED (2026-09-15) — Phase 1 built; app builds, 46/46 tests green

### CONSTRUCTION (v2) — Phase 1b (Onboarding v5 deltas)
- [x] Functional Design — APPROVED (2026-10-06). Answers: Q1–Q7=A, Q8=B.
- [x] NFR Requirements — APPROVED (2026-10-06)
- [x] NFR Design — APPROVED (2026-10-06)
- [x] Infrastructure Design — SKIPPED (no new infra; Firebase/HealthKit/targets reused)
- [x] Code Generation — COMPLETED + APPROVED (2026-10-06). App builds, full test suite green, SECURITY-03 clean. Committed e85fdf4.
- **Phase 1b COMPLETE.** Next: Phase 2 (Foundation protocols + coaching + cooldown + scoring) — functional-design questions in phase2-protocols-coaching-functional-design-plan.md still UNANSWERED.

### CONSTRUCTION (v2) — Phase 2 (Foundation Protocols + Coaching + Cooldown + Scoring)
- [x] Functional Design — APPROVED (2026-10-07). Answers Q1–Q11 all A (Q8 A + user-paced transition gate). PRODUCT NOTE flagged: treadmill→stretch transition gate for collaborator confirmation.
- [x] NFR Requirements — APPROVED (2026-10-07)
- [x] NFR Design — APPROVED (2026-10-07)
- [x] Infrastructure Design — SKIPPED (no new infra; Firebase/HealthKit/Watch/audio reused)
- [x] Code Generation — COMPLETED + APPROVED (2026-10-07). Core d7f45c1; app-side flow switch 6aa49c1. Full suite green (84 tests); SECURITY-03 clean.
  - DEFERRED within Phase 2 (flagged in code-summary): advanced §J in v2 driver (dropout UI, pause 15-min prompt/snoozes, elevated-HR walk_fallback) + on-device verification → Build & Test / focused follow-up before TestFlight.
- **Phase 2 COMPLETE.** Also pending: Build & Test stage (incl. deferred §J + device verification).

### CONSTRUCTION (v2) — Phase 3 (Progression & Assignment)
- [x] Functional Design — APPROVED (2026-10-09). Answers Q1–Q4=A, Q5=B (spec-literal relapse), Q6–Q9=A.
- [x] NFR Requirements — APPROVED (2026-10-09)
- [x] NFR Design — APPROVED (2026-10-09)
- [x] Infrastructure Design — SKIPPED (no new infra)
- [x] Code Generation — COMPLETED + APPROVED (2026-10-09). Committed a6670e4. Full suite green (103 tests); SECURITY-03 clean.
  - Notes: minimum walk resets relapse clock but doesn't persist a Session record in P3 (research-logging → P6); §J walk_fallback shares this plumbing (→ Build & Test).
- **Phase 3 COMPLETE.** Pending: Build & Test (deferred §J + device verification).

### CONSTRUCTION (v2) — Phase 4 (Level Up)
- [x] Functional Design — APPROVED (2026-10-11). Answers Q1–Q9 all A. FLAGGED for collaborator: leg-bank size (8 vs "20+") + per-exercise mode/joint tags (safety-relevant).
- [x] NFR Requirements — APPROVED (2026-10-11)
- [x] NFR Design — APPROVED (2026-10-11)
- [x] Infrastructure Design — SKIPPED (no new infra)
- [x] Code Generation — COMPLETED + APPROVED (2026-10-11). Committed 7e496c2. Full suite green (116 tests); SECURITY-03 clean.
  - Deferred (flagged): literal per-rep synced voice count + HIIT unilateral per-leg + tick-granularity timing → Build & Test; leg-bank size + mode/joint tags → collaborator confirm.
- **Phase 4 COMPLETE.** (User chose consolidated approach: finish P5, then one Build & Test pass.)

### CONSTRUCTION (v2) — Phase 5 (Shape)
- [x] Functional Design — APPROVED (2026-10-11). Answers Q1–Q10 all A (Q8 checks ~15s/40s). FLAGGED for collaborator: weight banks (§G transcription + muscle mapping).
- [x] NFR Requirements — APPROVED (2026-10-11)
- [x] NFR Design — APPROVED (2026-10-11)
- [x] Infrastructure Design — SKIPPED (no new infra)
- [x] Code Generation — COMPLETED + APPROVED (2026-10-11). Committed b263106. Full suite green (127 tests); SECURITY-03 clean.
  - Deferred (flagged): per-rep voice count, Shape-HIIT offset tuning, exercise-phase internal timing approximation → Build & Test; weight banks → collaborator confirm.
- **Phase 5 COMPLETE.** All 3 designed training stages built; Maintain out of scope.

### CONSTRUCTION (v2) — Phase 6 (Milestones, Reminders, Export, Client PDF)
- [x] Functional Design — APPROVED (2026-10-12); Q1–Q9 all A. Q3 "block workout start" flagged for collaborator.
- [x] NFR Requirements — APPROVED (2026-10-12)
- [x] NFR Design — APPROVED (2026-10-12)
- [x] Infrastructure Design — APPROVED (2026-10-12)
- [x] Code Generation — COMPLETED + APPROVED (2026-10-12). Committed 7141536. Full suite green (134 tests); SECURITY-03 clean.
- **Phase 6 COMPLETE.** All 6 build phases done. Remaining AI-DLC stage: **Build & Test** (consolidated device pass + deferred §J + owner deploy: Storage rules).

### Build & Test (deferred backlog, consolidated pass after P5)
- §J advanced safety (dropout UI, pause 15-min prompt/snoozes, elevated-HR walk_fallback)
- P4 refinements: literal per-rep synced voice count, HIIT unilateral per-leg, tick-granularity timing
- On-device Watch/HealthKit verification; collaborator confirms (leg-bank size, exercise tags)
