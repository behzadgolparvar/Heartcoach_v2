import XCTest
import HeartRateCoachCore

/// BR-2-12/13/14 — scoring over scored phases only, tier boundaries, exclusions.
final class SessionScorerTests: XCTestCase {

    private let rhr = 60, maxHR = 190
    private let proto = FoundationProtocolBuilder.build(type: .continuous)
    private var zones: HRZones { try! ZoneCalculator.calculate(age: 30, restingHR: rhr).zones }

    /// Build k in-range + m out-of-range samples in scored phase 0 (warm-up).
    private func samples(inRange k: Int, outOfRange m: Int, extraCooldownOut: Int = 0) -> [HRSample] {
        var out: [HRSample] = []
        out += Array(repeating: HRSample(phaseIndex: 0, hr: 130), count: k)   // 125…138 → in
        out += Array(repeating: HRSample(phaseIndex: 0, hr: 200), count: m)   // out (too high)
        if extraCooldownOut > 0 {
            let coolIdx = proto.phases.firstIndex { $0.kind == .cooldown }!
            out += Array(repeating: HRSample(phaseIndex: coolIdx, hr: 200), count: extraCooldownOut)
        }
        return out
    }

    private func score(_ s: [HRSample]) -> SessionScore {
        SessionScorer.score(protocol: proto, samples: s, restingHR: rhr, maxHR: maxHR, zones: zones)
    }

    func test_allInRange_isExcellent100() {
        let s = score(samples(inRange: 50, outOfRange: 0))
        XCTAssertEqual(s.percentInTarget, 100, accuracy: 0.001)
        XCTAssertEqual(s.tier, .excellent)
    }

    func test_allOutOfRange_isNeedsWork0() {
        let s = score(samples(inRange: 0, outOfRange: 50))
        XCTAssertEqual(s.percentInTarget, 0, accuracy: 0.001)
        XCTAssertEqual(s.tier, .needsWork)
    }

    func test_tierBoundaries() {
        XCTAssertEqual(score(samples(inRange: 90, outOfRange: 10)).tier, .excellent) // 90
        XCTAssertEqual(score(samples(inRange: 89, outOfRange: 11)).tier, .great)     // 89
        XCTAssertEqual(score(samples(inRange: 60, outOfRange: 40)).tier, .good)      // 60
        XCTAssertEqual(score(samples(inRange: 59, outOfRange: 41)).tier, .fair)      // 59
        XCTAssertEqual(score(samples(inRange: 40, outOfRange: 60)).tier, .fair)      // 40
        XCTAssertEqual(score(samples(inRange: 39, outOfRange: 61)).tier, .needsWork) // 39
    }

    func test_cooldownExcludedFromDenominator() {
        // 90 in + 10 out in training, plus 100 out-of-range cooldown seconds.
        let s = score(samples(inRange: 90, outOfRange: 10, extraCooldownOut: 100))
        XCTAssertEqual(s.percentInTarget, 90, accuracy: 0.001)   // cooldown ignored
        XCTAssertEqual(s.tier, .excellent)
    }

    func test_emptySamples_isNeedsWorkNotCrash() {
        let s = score([])
        XCTAssertEqual(s.percentInTarget, 0, accuracy: 0.001)
        XCTAssertEqual(s.tier, .needsWork)
    }
}
