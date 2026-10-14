import XCTest
import HeartRateCoachCore

/// BR-2-1/2/3 — protocol builder produces spec-matching timelines + bpm ranges.
final class FoundationProtocolTests: XCTestCase {

    private let rhr = 60, maxHR = 190   // age 30 → HRR 130

    func test_continuous_has7Blocks_bufferTransitionCooldown() {
        let p = FoundationProtocolBuilder.build(type: .continuous)
        let scored = p.phases.filter { $0.kind.isScored }
        XCTAssertEqual(scored.count, 7)                       // 7 blocks (incl. warm-up)
        XCTAssertEqual(p.phases.filter { $0.kind == .buffer }.count, 1)
        XCTAssertEqual(p.phases.filter { $0.kind == .transition }.count, 1)
        XCTAssertEqual(p.phases.filter { $0.kind == .cooldown }.count, 6)
        XCTAssertEqual(p.trainingDurationSec, 2100)           // 7 × 300
    }

    func test_continuous_block1And5_bpmRanges() {
        let p = FoundationProtocolBuilder.build(type: .continuous)
        // Block 1 = 50–60%HRR → 125…138 bpm.
        let b1 = p.phases[0].target!.bpmRange(restingHR: rhr, maxHR: maxHR)
        XCTAssertEqual(b1, 125...138)
        // Block 5 (peak) = 75–85%HRR → 158…171 bpm.
        let b5 = p.phases[4].target!.bpmRange(restingHR: rhr, maxHR: maxHR)
        XCTAssertEqual(b5, 158...171)
    }

    func test_hiit_15rounds_restsExcludedFromTraining() {
        let p = FoundationProtocolBuilder.build(type: .hiit)
        XCTAssertEqual(p.phases.filter { $0.kind == .work }.count, 15)
        XCTAssertEqual(p.phases.filter { $0.kind == .rest }.count, 15)
        XCTAssertEqual(p.phases.filter { $0.kind == .warmup }.count, 1)
        XCTAssertEqual(p.phases.filter { $0.kind == .buffer }.count, 0) // HIIT has no buffer
        // Training = warm-up 300 + 15 work × 60 = 1200 (rest excluded).
        XCTAssertEqual(p.trainingDurationSec, 1200)
    }

    func test_hiit_round9_is80to90pct() {
        let p = FoundationProtocolBuilder.build(type: .hiit)
        let round9 = p.phases.first { $0.label == "Round 9" }!
        XCTAssertEqual(round9.target!.lowPctHRR, 0.80, accuracy: 0.0001)
        XCTAssertEqual(round9.target!.highPctHRR, 0.90, accuracy: 0.0001)
    }

    func test_cooldown_totals120s() {
        XCTAssertEqual(CooldownStep.totalDurationSec, 120)
    }

    func test_transitionPhase_hasNoDuration() {
        let p = FoundationProtocolBuilder.build(type: .continuous)
        let gate = p.phases.first { $0.kind == .transition }!
        XCTAssertNil(gate.durationSec)   // user-paced (Q8)
    }
}
