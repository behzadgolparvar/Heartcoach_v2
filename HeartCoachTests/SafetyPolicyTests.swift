import XCTest
import HeartRateCoachCore

/// §J safety policy — snooze cap + elevated-start-HR decision.
final class SafetyPolicyTests: XCTestCase {

    func test_snoozeCap() {
        XCTAssertTrue(SafetyPolicy.canSnooze(usedSnoozes: 0))
        XCTAssertTrue(SafetyPolicy.canSnooze(usedSnoozes: 2))
        XCTAssertFalse(SafetyPolicy.canSnooze(usedSnoozes: 3))
        XCTAssertFalse(SafetyPolicy.canSnooze(usedSnoozes: 4))
    }

    func test_elevatedStartHR() {
        // rhr 60, maxHR 190 → HRR 130; threshold = 60 + 0.40*130 = 112.
        XCTAssertFalse(SafetyPolicy.isElevatedStartHR(hr: 70, restingHR: 60, maxHR: 190))
        XCTAssertFalse(SafetyPolicy.isElevatedStartHR(hr: 112, restingHR: 60, maxHR: 190))
        XCTAssertTrue(SafetyPolicy.isElevatedStartHR(hr: 120, restingHR: 60, maxHR: 190))
    }

    func test_constants() {
        XCTAssertEqual(SafetyPolicy.sensorDropoutSec, 20)
        XCTAssertEqual(SafetyPolicy.pausePromptMinutes, 15)
        XCTAssertEqual(SafetyPolicy.maxPauseSnoozes, 3)
    }

    func test_walkFallbackProtocol_structure() {
        let p = FoundationProtocolBuilder.walkFallback()
        // 15 brisk + 15 easy walk phases (all unscored rest), then transition + cooldown.
        XCTAssertEqual(p.phases.filter { $0.kind == .rest }.count, 30)
        XCTAssertEqual(p.phases.filter { $0.kind == .cooldown }.count, 6)
        XCTAssertEqual(p.phases.filter { $0.kind == .transition }.count, 1)
        XCTAssertEqual(p.trainingDurationSec, 0)   // nothing scored
        XCTAssertFalse(p.phases.contains { $0.kind.isScored })
    }

    func test_walkFallback_excludedFromProgression() {
        // ProgressionEngine.advance counts only scored continuous/hiit — walk_fallback must not advance.
        let program = ProgramState.newUser()
        let after = ProgressionEngine.advance(program: program, sessionFlag: "walk_fallback",
                                              trainingDurationSec: 1800, date: Date())
        XCTAssertEqual(after.currentProgress.sessionsCompleted, 0)
    }
}
