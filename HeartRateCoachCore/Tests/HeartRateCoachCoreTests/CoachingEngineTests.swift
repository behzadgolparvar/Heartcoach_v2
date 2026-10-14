import XCTest
@testable import HeartRateCoachCore

final class CoachingEngineTests: XCTestCase {

    // MARK: - Test Fixtures

    private var zones: HRZones!

    override func setUp() {
        super.setUp()
        // Zone5 max = 190 for a 30-year-old with RHR 60 (Karvonen)
        zones = try! ZoneCalculator.calculate(age: 30, restingHR: 60).zones
    }

    private func makePhase(targetZone: Int?, hasGracePeriod: Bool = false) -> WorkoutPhase {
        WorkoutPhase(index: 0, duration: 300, targetZone: targetZone, type: .exercise, hasGracePeriod: hasGracePeriod)
    }

    private let pastAntiSpam = Date(timeIntervalSinceNow: -25)  // > 20s ago — anti-spam cleared
    private let recentAntiSpam = Date(timeIntervalSinceNow: -10) // < 20s ago — still in cooldown

    // MARK: - Layer 1: Safety

    func test_layer1_firesEmergencyStop_whenHRAboveZone5Max() {
        var state = CoachingEngineState(hrBuffer: [zones.zone5.max + 5])
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: zones.zone5.max + 5, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(msg, .emergencyStop)
    }

    func test_layer1_firesCriticalSlowDown_whenHRNearZone5Max() {
        let criticalHR = Int(Double(zones.zone5.max) * 0.96)
        var state = CoachingEngineState(hrBuffer: [criticalHR])
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: criticalHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(msg, .criticalSlowDown)
    }

    func test_layer1_firesNoSignal_whenHRIsStale() {
        var state = CoachingEngineState()
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: Int.max, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(msg, .noSignal)
    }

    func test_layer1_resetsInZoneCounter() {
        var state = CoachingEngineState(hrBuffer: [zones.zone5.max + 1], consecutiveInZoneSeconds: 20)
        let phase = makePhase(targetZone: 3)

        _ = CoachingEngine.tick(hr: zones.zone5.max + 1, phase: phase,
                                elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(state.consecutiveInZoneSeconds, 0)
    }

    // MARK: - Layer 2: Zone Coaching

    func test_layer2_firesSpeedUp_whenHRBelowTargetZone() {
        let zone3 = zones.zone(number: 3)!
        let lowHR = zone3.min - 5
        var state = CoachingEngineState(hrBuffer: [lowHR])
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: lowHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones,
                                     now: Date(timeIntervalSinceNow: 0))

        XCTAssertEqual(msg, .speedUp)
    }

    func test_layer2_firesSlowDown_whenHRAboveTargetZone() {
        let zone3 = zones.zone(number: 3)!
        let highHR = zone3.max + 5
        var state = CoachingEngineState(hrBuffer: [highHR])
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: highHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(msg, .slowDown)
    }

    func test_layer2_suppressedDuringGracePeriod() {
        let zone3 = zones.zone(number: 3)!
        let lowHR = zone3.min - 5
        var state = CoachingEngineState(hrBuffer: [lowHR])
        let phase = makePhase(targetZone: 3, hasGracePeriod: true)

        let msg = CoachingEngine.tick(hr: lowHR, phase: phase,
                                     elapsedInPhase: 5, state: &state, zones: zones)

        XCTAssertNil(msg)
    }

    func test_layer2_suppressedByAntiSpam() {
        let zone3 = zones.zone(number: 3)!
        let lowHR = zone3.min - 5
        var state = CoachingEngineState(hrBuffer: [lowHR], lastLayer2MessageAt: recentAntiSpam)
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: lowHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertNil(msg)
    }

    func test_layer2_allowedAfterAntiSpamExpires() {
        let zone3 = zones.zone(number: 3)!
        let lowHR = zone3.min - 5
        var state = CoachingEngineState(hrBuffer: [lowHR], lastLayer2MessageAt: pastAntiSpam)
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: lowHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(msg, .speedUp)
    }

    // MARK: - Layer 3: Positive Feedback

    func test_layer3_firesKeepItUp_after30SecondsInZone() {
        let zone3 = zones.zone(number: 3)!
        let inZoneHR = (zone3.min + zone3.max) / 2
        var state = CoachingEngineState(hrBuffer: [inZoneHR], consecutiveInZoneSeconds: 25)
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: inZoneHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(msg, .keepItUp)
    }

    func test_layer3_doesNotFire_before30Seconds() {
        let zone3 = zones.zone(number: 3)!
        let inZoneHR = (zone3.min + zone3.max) / 2
        // An in-zone tick adds +10 (Layer 2's in-zone counter and Layer 3 each add 5),
        // so start low enough that it stays under the 30s threshold after this tick.
        var state = CoachingEngineState(hrBuffer: [inZoneHR], consecutiveInZoneSeconds: 10)
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: inZoneHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertNil(msg)
    }

    // MARK: - Mutual Exclusion

    func test_mutualExclusion_layer1WinsOverLayer2() {
        let emergencyHR = zones.zone5.max + 10
        var state = CoachingEngineState(hrBuffer: [emergencyHR])
        let phase = makePhase(targetZone: 3)

        let msg = CoachingEngine.tick(hr: emergencyHR, phase: phase,
                                     elapsedInPhase: 30, state: &state, zones: zones)

        XCTAssertEqual(msg?.layer, 1, "Layer 1 should win — got layer \(msg?.layer ?? -1)")
    }

    // MARK: - PBT: 9 Invariants (seeded)

    func test_pbt_layer1AlwaysFires_whenHRAboveZone5Max() {
        pbtAssert("Layer 1 always fires when HR > zone5.max regardless of state",
                  gen: { (genCoachingEngineState(&$0), genWorkoutPhase(&$0)) }) { stateIn, phase in
            var state = stateIn
            let hr = self.zones.zone5.max + 1
            // Safety is evaluated on the smoothed buffer HR — seed the buffer with the
            // emergency reading so the smoothed value actually exceeds zone5.max.
            state.hrBuffer = [hr]
            let msg = CoachingEngine.tick(hr: hr, phase: phase, elapsedInPhase: 30,
                                         state: &state, zones: self.zones)
            return msg?.layer == 1
        }
    }

    func test_pbt_layer2NeverFires_whenPhaseHasNoTargetZone() {
        pbtAssert("Layer 2 never fires when phase.targetZone == nil",
                  gen: genCoachingEngineState) { stateIn in
            var state = stateIn
            let phase = WorkoutPhase(index: 0, duration: 300, targetZone: nil,
                                    type: .recovery, hasGracePeriod: false)
            let hr = 130
            state.hrBuffer = [hr]
            let msg = CoachingEngine.tick(hr: hr, phase: phase, elapsedInPhase: 30,
                                         state: &state, zones: self.zones)
            return msg?.layer != 2
        }
    }

    func test_pbt_layer2NeverFires_duringGracePeriod() {
        pbtAssert("Layer 2 never fires when elapsedInPhase < 10",
                  gen: genCoachingEngineState) { stateIn in
            var state = stateIn
            state.hrBuffer = [120]
            let phase = WorkoutPhase(index: 0, duration: 300, targetZone: 3,
                                    type: .exercise, hasGracePeriod: true)
            let msg = CoachingEngine.tick(hr: 120, phase: phase, elapsedInPhase: 5,
                                         state: &state, zones: self.zones)
            return msg?.layer != 2
        }
    }

    func test_pbt_layer2NeverFires_withinAntiSpamWindow() {
        pbtAssert("Layer 2 never fires within 20 seconds of last Layer 2 message",
                  gen: { (genCoachingEngineState(&$0), genWorkoutPhaseWithZone(&$0)) }) { stateIn, phase in
            var state = stateIn
            let now = Date()
            state.lastLayer2MessageAt = now.addingTimeInterval(-10)  // 10s ago — inside window
            state.hrBuffer = [80]
            let msg = CoachingEngine.tick(hr: 80, phase: phase, elapsedInPhase: 30,
                                         state: &state, zones: self.zones, now: now)
            return msg?.layer != 2
        }
    }

    func test_pbt_layer3NeverFires_whenConsecutiveSecondsBelowThreshold() {
        pbtAssert("Layer 3 never fires when consecutiveInZoneSeconds stays below 30 after the tick",
                  gen: { (genCoachingEngineState(&$0), genWorkoutPhaseWithZone(&$0)) }) { stateIn, phase in
            var state = stateIn
            // An in-zone tick adds +10 (Layer 2 counter + Layer 3), so 15 → 25 < 30.
            state.consecutiveInZoneSeconds = 15
            let targetZone = phase.targetZone!
            let zone = self.zones.zone(number: targetZone)!
            let inZoneHR = (zone.min + zone.max) / 2
            state.hrBuffer = [inZoneHR]
            let msg = CoachingEngine.tick(hr: inZoneHR, phase: phase, elapsedInPhase: 30,
                                         state: &state, zones: self.zones)
            return msg?.layer != 3
        }
    }

    func test_pbt_atMostOneLayerFiresPerTick() {
        pbtAssert("At most one layer fires per tick",
                  gen: { (genCoachingEngineState(&$0), genWorkoutPhase(&$0)) }) { stateIn, phase in
            var state = stateIn
            let hr = 130
            state.hrBuffer = [hr]
            let msg = CoachingEngine.tick(hr: hr, phase: phase, elapsedInPhase: 30,
                                         state: &state, zones: self.zones)
            // By design, tick returns 0 or 1 message — this invariant is structural
            return msg == nil || (msg!.layer >= 1 && msg!.layer <= 3)
        }
    }

    func test_pbt_hrSmooth_withinBufferBounds() {
        pbtAssert("hrSmooth is always within [min(hrBuffer), max(hrBuffer)]",
                  gen: genCoachingEngineState) { stateIn in
            let state = stateIn
            guard !state.hrBuffer.isEmpty else { return true }
            let smooth = state.hrSmooth
            return smooth >= state.hrBuffer.min()! && smooth <= state.hrBuffer.max()! + 1
            // +1 accounts for ceiling rounding
        }
    }

    func test_pbt_consecutiveInZoneSeconds_neverNegative() {
        pbtAssert("consecutiveInZoneSeconds is always >= 0 after any tick",
                  gen: { (genCoachingEngineState(&$0), genWorkoutPhase(&$0)) }) { stateIn, phase in
            var state = stateIn
            let hr = 130
            state.hrBuffer = [hr]
            _ = CoachingEngine.tick(hr: hr, phase: phase, elapsedInPhase: 30,
                                   state: &state, zones: self.zones)
            return state.consecutiveInZoneSeconds >= 0
        }
    }

    func test_pbt_determinism_sameInputsSameOutput() {
        pbtAssert("Same inputs always produce the same output",
                  gen: { (genCoachingEngineState(&$0), genWorkoutPhase(&$0)) }) { stateIn, phase in
            let hr = 130
            let now = Date(timeIntervalSince1970: 1_000_000)  // fixed time
            var state1 = stateIn
            var state2 = stateIn
            state1.hrBuffer = [hr]; state2.hrBuffer = [hr]
            let msg1 = CoachingEngine.tick(hr: hr, phase: phase, elapsedInPhase: 30,
                                          state: &state1, zones: self.zones, now: now)
            let msg2 = CoachingEngine.tick(hr: hr, phase: phase, elapsedInPhase: 30,
                                          state: &state2, zones: self.zones, now: now)
            return msg1 == msg2
        }
    }
}
