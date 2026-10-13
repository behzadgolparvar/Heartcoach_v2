# Unit & Property-Based Test Instructions — HeartCoach v5

## Run the full suite
```
xcodebuild test -project HeartCoach.xcodeproj -scheme HeartCoach \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
Current baseline: **134 tests, 0 failures.** (The `VoiceDBClient … Using fallback voices` console line is a harmless simulator warning.)

## Coverage by phase (pure logic / PBT-partial, in the app test target)
- **P1b:** `ExperienceResolverTests` (24-combo matrix + Ozempic), `StageProgressTests`, `ProfileV5CodableTests` (incl. pre-v5 decode)
- **P2:** `FoundationProtocolTests`, `CoachingEngineV2Tests` (severity ±5, escalation, no-3×-repeat under seed), `SessionScorerTests` (tier boundaries, exclusions), `BriefingPolicyTests`
- **P3:** `ProgressionTablesTests` (every §B cell), `ProgressionEngineTests` (assignment cycles, advancement gating, relapse Q5=B, minimum)
- **P4:** `LevelUpTests` (exclusion, no-repeat selection, both timelines, mode timing, unlock Codable)
- **P5:** `ShapeTests` (4-2/6-5 alternation, Legs rule, both timelines, banks, unlock Codable)
- **P6:** `EngagementTests` (milestone cadence/gate, reminders no-health-text, CSV, 60-row plan, persistence)

## Targeted run (one suite)
```
xcodebuild test ... -only-testing:HeartCoachTests/ProgressionEngineTests
```

## When adding §J / refinement code (backlog A/B)
- Keep logic pure where possible and add deterministic tests (inject `now`/seed) — mirror the existing engines.
- Re-run the full suite; keep it green before each device build.

## Property-based (partial) checklist
Deterministic, seeded, boundary-focused — already covered: zone/HRR math, resolver matrix, coaching selection + rotation, scorer tiers, ratio tables + progression + relapse, exercise selection/exclusion, Shape alternation, milestone boundaries, CSV mapping, session-plan projection.
