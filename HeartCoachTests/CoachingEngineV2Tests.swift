import XCTest
import HeartRateCoachCore

/// BR-2-5/6/7/8/9 — CoachingEngine v2 layering, severity, escalation, rotation.
final class CoachingEngineV2Tests: XCTestCase {

    private let rhr = 60, maxHR = 190
    // Continuous Block 1 target: 50–60%HRR → 125…138 bpm.
    private var block1: FoundationPhase { FoundationProtocolBuilder.build(type: .continuous).phases[0] }
    private var target: ClosedRange<Int> { block1.target!.bpmRange(restingHR: rhr, maxHR: maxHR) }

    private func mkTick(hr: Int, elapsed: Int = 60, start: Bool = false,
                        sessionSec: Int = 60, threshold: Int = 60) -> CoachingEngineV2.Tick {
        CoachingEngineV2.Tick(hr: hr, phase: block1, bpmTarget: target,
                              phaseElapsedSec: elapsed, phaseDurationSec: 300,
                              isPhaseStart: start, itemsLeft: nil,
                              escalationThresholdSec: threshold, sessionSec: sessionSec)
    }

    func test_offZone_severityAndDirection() {
        var s = CoachingSessionState(seed: 1)
        // 138 is the top of range; 140 = 2 over → minor high.
        XCTAssertEqual(CoachingEngineV2.tick(mkTick(hr: 140), state: &s)?.category, .offMinorHigh)
        var s2 = CoachingSessionState(seed: 1)
        // 143 = 5 over → major high.
        XCTAssertEqual(CoachingEngineV2.tick(mkTick(hr: 143), state: &s2)?.category, .offMajorHigh)
        var s3 = CoachingSessionState(seed: 1)
        // 123 = 2 under (low edge 125) → minor low.
        XCTAssertEqual(CoachingEngineV2.tick(mkTick(hr: 123), state: &s3)?.category, .offMinorLow)
        var s4 = CoachingSessionState(seed: 1)
        // 120 = 5 under → major low.
        XCTAssertEqual(CoachingEngineV2.tick(mkTick(hr: 120), state: &s4)?.category, .offMajorLow)
    }

    func test_inRange_midPhase_emitsNothing() {
        var s = CoachingSessionState(seed: 1)
        let cue = CoachingEngineV2.tick(mkTick(hr: 130, elapsed: 60), state: &s)
        XCTAssertNil(cue)   // in range, not late enough for in-zone, not a phase start
    }

    func test_offZone_priorityOverTransitionAtStart() {
        var s = CoachingSessionState(seed: 1)
        // Phase start + off-zone: off-zone outranks the transition announce.
        let cue = CoachingEngineV2.tick(mkTick(hr: 150, elapsed: 0, start: true), state: &s)
        XCTAssertEqual(cue?.priority, .offZone)
    }

    func test_escalation_afterSustainedOffZone() {
        var s = CoachingSessionState(seed: 1)
        var last: CoachingCue?
        // Continuous threshold 60s; 15s ticks → 4th tick reaches 60s off.
        for i in 1...4 {
            last = CoachingEngineV2.tick(mkTick(hr: 150, elapsed: i * 15, sessionSec: i * 15), state: &s)
        }
        XCTAssertEqual(last?.priority, .escalation)
        XCTAssertEqual(last?.category, .escalationHigh)
    }

    func test_escalation_resetsOnReentry() {
        var s = CoachingSessionState(seed: 1)
        for i in 1...3 { _ = CoachingEngineV2.tick(mkTick(hr: 150, elapsed: i*15, sessionSec: i*15), state: &s) }
        _ = CoachingEngineV2.tick(mkTick(hr: 130, elapsed: 60, sessionSec: 60), state: &s) // back in range
        XCTAssertEqual(s.offRunSec, 0)
    }

    func test_inZone_atMostOncePerBlock_andLate() {
        var s = CoachingSessionState(seed: 1)
        var inZoneCount = 0
        // 20 ticks in range across the block; in-zone should fire exactly once, late.
        for i in 1...20 {
            let cue = CoachingEngineV2.tick(mkTick(hr: 130, elapsed: i * 15, sessionSec: i * 15), state: &s)
            if cue?.category == .inZone { inZoneCount += 1 }
        }
        XCTAssertEqual(inZoneCount, 1)
    }

    func test_noPhraseThreeTimesInARow() {
        var s = CoachingSessionState(seed: 42)
        var phrases: [String] = []
        for i in 1...40 {
            if let cue = CoachingEngineV2.tick(mkTick(hr: 150, elapsed: 60, sessionSec: i * 15, threshold: 100000), state: &s) {
                phrases.append(cue.text)   // high threshold suppresses escalation → steady off-zone pool
            }
        }
        XCTAssertGreaterThan(phrases.count, 5)
        for i in 2..<phrases.count {
            XCTAssertFalse(phrases[i] == phrases[i-1] && phrases[i] == phrases[i-2],
                           "phrase repeated 3× at index \(i): \(phrases[i])")
        }
    }

    func test_restPhase_emitsInstructionAtStartOnly() {
        let hiit = FoundationProtocolBuilder.build(type: .hiit)
        let rest = hiit.phases.first { $0.kind == .rest }!
        var s = CoachingSessionState(seed: 1)
        let startTick = CoachingEngineV2.Tick(hr: 110, phase: rest, bpmTarget: nil,
            phaseElapsedSec: 0, phaseDurationSec: 60, isPhaseStart: true,
            itemsLeft: nil, escalationThresholdSec: 30, sessionSec: 100)
        XCTAssertEqual(CoachingEngineV2.tick(startTick, state: &s)?.category, .restInstruction)
        let midTick = CoachingEngineV2.Tick(hr: 110, phase: rest, bpmTarget: nil,
            phaseElapsedSec: 30, phaseDurationSec: 60, isPhaseStart: false,
            itemsLeft: nil, escalationThresholdSec: 30, sessionSec: 130)
        XCTAssertNil(CoachingEngineV2.tick(midTick, state: &s))
    }
}
