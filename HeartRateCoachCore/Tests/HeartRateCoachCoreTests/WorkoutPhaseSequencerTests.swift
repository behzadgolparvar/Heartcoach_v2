import XCTest
import SwiftCheck
@testable import HeartRateCoachCore

final class WorkoutPhaseSequencerTests: XCTestCase {

    // MARK: - Example-Based Tests

    func testContinuousTotalDuration() {
        let total = WorkoutProgram.continuous.phases.reduce(0.0) { $0 + $1.duration }
        XCTAssertEqual(total, 2100, "Continuous total must be 35 minutes (2100 seconds)")
    }

    func testHIITTotalDuration() {
        let total = WorkoutProgram.hiit.phases.reduce(0.0) { $0 + $1.duration }
        XCTAssertEqual(total, 2100, "HIIT total must be 35 minutes (2100 seconds)")
    }

    func testFartlekTotalDuration() {
        let total = WorkoutProgram.fartlek.phases.reduce(0.0) { $0 + $1.duration }
        XCTAssertEqual(total, 2100, "Fartlek total must be 35 minutes (2100 seconds)")
    }

    func testPhaseAdvancement() {
        var seq = WorkoutPhaseSequencer(program: .continuous)
        XCTAssertEqual(seq.currentPhase.index, 0)
        XCTAssertEqual(seq.currentPhase.type, .warmup)

        // Advance past the first phase (120 seconds warm-up)
        let event = seq.advance(by: 121)
        guard case .phaseTransition(let newPhase) = event else {
            return XCTFail("Expected phaseTransition, got \(event)")
        }
        XCTAssertEqual(newPhase.index, 1)
    }

    func testGracePeriodActiveFirst10Seconds() {
        var seq = WorkoutPhaseSequencer(program: .hiit)
        // Advance to first HIIT exercise phase (index 2, starts at 300s)
        seq.advance(by: 301)
        XCTAssertEqual(seq.currentPhase.type, .exercise)
        XCTAssertTrue(seq.isGracePeriodActive, "Grace period should be active within first 10 seconds")
    }

    func testGracePeriodInactiveAfter10Seconds() {
        var seq = WorkoutPhaseSequencer(program: .hiit)
        // Advance to first HIIT exercise phase and past grace period
        seq.advance(by: 300)  // end of warm-up
        seq.advance(by: 11)   // 11 seconds into exercise phase
        XCTAssertFalse(seq.isGracePeriodActive, "Grace period should be inactive after 10 seconds")
    }

    func testGracePeriodNotApplicableToContinuous() {
        var seq = WorkoutPhaseSequencer(program: .continuous)
        // Advance to first exercise phase (index 2, starts at 300s)
        seq.advance(by: 301)
        XCTAssertEqual(seq.currentPhase.type, .exercise)
        XCTAssertFalse(seq.isGracePeriodActive, "Continuous training has no grace period")
    }

    func testWorkoutCompleteSignalFired() {
        var seq = WorkoutPhaseSequencer(program: .continuous)
        let event = seq.advance(by: 2101) // past the entire 35-minute program
        guard case .mainWorkoutComplete = event else {
            return XCTFail("Expected mainWorkoutComplete, got \(event)")
        }
        XCTAssertTrue(seq.isComplete)
    }

    func testFartlekZoneSequence() {
        let phases = WorkoutProgram.fartlek.phases
        // Skip 2 warm-up phases; verify the 15 training segments match the specified sequence
        let expectedZones = [2, 3, 2, 3, 4, 2, 3, 4, 3, 4, 3, 4, 2, 3, 5]
        let trainingPhases = phases.filter { $0.type == .exercise }
        XCTAssertEqual(trainingPhases.count, 15)
        for (i, phase) in trainingPhases.enumerated() {
            XCTAssertEqual(phase.targetZone, expectedZones[i],
                           "Fartlek segment \(i + 1): expected zone \(expectedZones[i]), got \(phase.targetZone ?? -1)")
        }
    }

    func testTimeRemainingInPhase() {
        var seq = WorkoutPhaseSequencer(program: .continuous)
        XCTAssertEqual(seq.timeRemainingInPhase, 120) // first phase is 120s
        seq.advance(by: 50)
        XCTAssertEqual(seq.timeRemainingInPhase, 70, accuracy: 0.01)
    }

    func testHIITPhaseCount() {
        XCTAssertEqual(WorkoutProgram.hiit.phases.count, 32)
        // 2 warm-up + 15 cycles × 2 = 32
    }

    // MARK: - Property-Based Tests (SwiftCheck)

    func testTotalDurationInvariant() {
        let programs: [WorkoutProgram] = [.continuous, .hiit, .fartlek]
        for program in programs {
            property("total duration of \(program) equals 2100 seconds")
                <- forAll(Gen.pure(program)) { p in
                    let total = p.phases.reduce(0.0) { $0 + $1.duration }
                    return total == 2100
                }
        }
    }
}
