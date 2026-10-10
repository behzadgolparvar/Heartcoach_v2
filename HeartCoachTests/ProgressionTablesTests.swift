import XCTest
import HeartRateCoachCore

/// Every §B ratio cell matches the spec.
final class ProgressionTablesTests: XCTestCase {

    private func r(_ track: ProgressionTrack, _ lean: MentalityLean) -> [SessionRatio?] {
        (0..<3).map { ProgressionTables.ratio(track: track, lean: lean, subPhase: $0) }
    }

    func test_beginnerFWL() {
        XCTAssertEqual(r(.beginnerFastWeightLoss, .outcome), [SessionRatio(1,2), SessionRatio(1,1), SessionRatio(2,1)])
        XCTAssertEqual(r(.beginnerFastWeightLoss, .mixed),   [SessionRatio(1,3), SessionRatio(1,2), SessionRatio(1,1)])
        XCTAssertEqual(r(.beginnerFastWeightLoss, .process), [SessionRatio(1,4), SessionRatio(1,3), SessionRatio(1,2)])
    }

    func test_intermediate() {
        XCTAssertEqual(r(.intermediate, .outcome), [SessionRatio(1,1), SessionRatio(2,1), SessionRatio(3,1)])
        XCTAssertEqual(r(.intermediate, .mixed),   [SessionRatio(1,2), SessionRatio(1,1), SessionRatio(2,1)])
        XCTAssertEqual(r(.intermediate, .process), [SessionRatio(1,3), SessionRatio(1,2), SessionRatio(1,1)])
    }

    func test_advanced() {
        XCTAssertEqual(r(.advanced, .outcome), [SessionRatio(2,1), SessionRatio(3,1), SessionRatio(4,1)])
        XCTAssertEqual(r(.advanced, .mixed),   [SessionRatio(1,1), SessionRatio(2,1), SessionRatio(3,1)])
        XCTAssertEqual(r(.advanced, .process), [SessionRatio(1,2), SessionRatio(1,1), SessionRatio(2,1)])
    }

    func test_routineCardio_hasNoRatio() {
        XCTAssertNil(ProgressionTables.ratio(track: .beginnerRoutineCardio, lean: .outcome, subPhase: 0))
    }

    func test_ratioCycle_frontLoadsHIIT() {
        XCTAssertEqual(SessionRatio(1,2).cycle, [.hiit, .continuous, .continuous])
        XCTAssertEqual(SessionRatio(2,1).cycle, [.hiit, .hiit, .continuous])
        XCTAssertEqual(SessionRatio(1,4).cycle, [.hiit, .continuous, .continuous, .continuous, .continuous])
    }
}
