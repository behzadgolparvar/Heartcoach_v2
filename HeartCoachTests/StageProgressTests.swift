import XCTest
import HeartRateCoachCore

/// BR-1b-7/8. Sub-phase + stage-completion over the full 0…60 range.
final class StageProgressTests: XCTestCase {

    func test_subPhase_overFullRange() {
        for n in 0...60 {
            let p = StageProgress(stage: .foundation, sessionsCompleted: n)
            let expected: Int
            switch n {
            case 0..<20:  expected = 0
            case 20..<40: expected = 1
            default:      expected = 2   // 40…60 (capped at 2)
            }
            XCTAssertEqual(p.subPhase, expected, "sessionsCompleted=\(n)")
        }
    }

    func test_subPhaseBoundaries() {
        XCTAssertEqual(StageProgress(stage: .foundation, sessionsCompleted: 19).subPhase, 0)
        XCTAssertEqual(StageProgress(stage: .foundation, sessionsCompleted: 20).subPhase, 1)
        XCTAssertEqual(StageProgress(stage: .foundation, sessionsCompleted: 39).subPhase, 1)
        XCTAssertEqual(StageProgress(stage: .foundation, sessionsCompleted: 40).subPhase, 2)
    }

    func test_isStageComplete() {
        XCTAssertFalse(StageProgress(stage: .foundation, sessionsCompleted: 59).isStageComplete)
        XCTAssertTrue(StageProgress(stage: .foundation, sessionsCompleted: 60).isStageComplete)
        XCTAssertTrue(StageProgress(stage: .foundation, sessionsCompleted: 61).isStageComplete)
    }

    func test_newUser_startsFoundationZero() {
        let p = ProgramState.newUser()
        XCTAssertEqual(p.currentStage, .foundation)
        XCTAssertEqual(p.currentProgress.sessionsCompleted, 0)
        XCTAssertEqual(p.currentProgress.subPhase, 0)
    }

    func test_stageOrderingAndNext() {
        XCTAssertTrue(TrainingStage.foundation < .levelUp)
        XCTAssertTrue(TrainingStage.levelUp < .shape)
        XCTAssertTrue(TrainingStage.shape < .maintain)
        XCTAssertEqual(TrainingStage.foundation.next, .levelUp)
        XCTAssertEqual(TrainingStage.shape.next, .maintain)
        XCTAssertNil(TrainingStage.maintain.next)
    }
}
