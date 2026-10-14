import XCTest
import HeartRateCoachCore

/// BR-2-11 — briefing mandatory for the first 4 scored sessions of a type per stage.
final class BriefingPolicyTests: XCTestCase {

    func test_mandatoryForFirstFour() {
        for count in 0...3 {
            XCTAssertTrue(BriefingPolicy.isMandatory(priorScoredSessionsOfTypeThisStage: count),
                          "should be mandatory at count \(count)")
        }
    }

    func test_skippableFromFifth() {
        XCTAssertFalse(BriefingPolicy.isMandatory(priorScoredSessionsOfTypeThisStage: 4))
        XCTAssertFalse(BriefingPolicy.isMandatory(priorScoredSessionsOfTypeThisStage: 10))
    }
}
