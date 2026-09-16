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
### INCEPTION PHASE (v2)
- [x] Workspace Detection — COMPLETED (2026-09-15) — brownfield
- [ ] Reverse Engineering — PROPOSED SKIP (pending approval)
- [ ] Requirements Analysis — IN PROGRESS (questions issued)
- [ ] User Stories — pending
- [ ] Workflow Planning — pending
- [ ] Application Design — pending
- [ ] Units Generation — pending (this produces the phased implementation plan)

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

## v2 Stage Progress (updated)
- [x] Requirements Analysis — COMPLETED (v2-requirements.md)
- [~] User Stories — SKIPPED (specs + requirements sufficient; user approved skip)
- [x] Workflow Planning — COMPLETED (execution: 5 phases, incremental)
- [x] Units Generation — COMPLETED (v2-phased-implementation-plan.md; 5 units)
- [ ] CONSTRUCTION — pending approval to begin Phase 1

### CONSTRUCTION (v2) — Phase 1 (Onboarding + Data Model)
- [x] Functional Design — COMPLETED (2026-09-15)
- [ ] NFR Requirements — next
- [ ] NFR Design — pending
- [ ] Code Generation — pending
- [x] NFR Requirements — COMPLETED (2026-09-15)
- [x] NFR Design — COMPLETED (2026-09-15)
- [x] Infrastructure Design — SKIPPED (no new infra; Firebase/HealthKit/targets reused)
