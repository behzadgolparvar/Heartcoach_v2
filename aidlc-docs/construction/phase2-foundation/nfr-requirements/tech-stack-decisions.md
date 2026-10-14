# Phase 2 — Tech Stack Decisions (Foundation Protocols + Coaching)

**No new technology decisions.** Phase 2 reuses the stack fixed in Phase 1 / v2 Requirements and the v1 real-time infrastructure.

| Concern | Decision | Status |
|---|---|---|
| Pure protocol/coaching/scoring logic | `HeartRateCoachCore` SPM package | Reused — `FoundationProtocolBuilder`, `CoachingEngineV2`, `SessionScorer`, `BriefingPolicy` land here |
| Coaching engine | **New `CoachingEngineV2`** alongside v1 engine (Q6=A); v1 untouched until the flow switches | New type, same package |
| Real-time HR | Apple Watch pipeline + `WCSession` + HealthKit workout session | Reused from v1 |
| Voice / haptics / audio session | v1 voice + haptic services | Reused |
| Session orchestration | v1 session-manager / tick loop | Reused, extended for new phases (buffer/transition/cooldown) + two clocks |
| Persistence | Firestore `sessions` + encoded `hr_stream`, offline-tolerant writes | Reused; add `phase` tag + score fields |
| Zones | Karvonen `ZoneCalculator` | Reused |
| Testing | App test target (XCTest) + PBT where pure; core SwiftCheck target excluded (Xcode 26) | Reused |
| Project gen | xcodegen | Reused |

## Placement rules for new code
- Pure logic (`FoundationProtocolBuilder`, `CoachingEngineV2`, `SessionScorer`, phrase pools, `BriefingPolicy`, protocol/score entities) → `HeartRateCoachCore`.
- Session-manager wiring (phase sequencing, two clocks, transition-gate, safety/edge handling) → app workout layer.
- UI (manual picker, in-session coaching text, cooldown steps + gate, summary) → app `Views/`.
- Persistence additions (`phase` tag, score fields, `session_flag`) → app `FirestoreService`.

No infrastructure changes → Infrastructure Design will be **SKIPPED** (consistent with Phase 1 / 1b).
