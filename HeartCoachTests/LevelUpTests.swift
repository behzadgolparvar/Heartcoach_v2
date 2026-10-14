import XCTest
import HeartRateCoachCore

/// BR-4-1..9 — leg bank, exclusion/selection, Level Up protocol timelines.
final class LevelUpTests: XCTestCase {

    private let bank = LegExerciseBank.all

    // MARK: - Joint mapping

    func test_jointIssueMapping() {
        XCTAssertEqual(LegJoint.from(.knees), .knee)
        XCTAssertEqual(LegJoint.from(.hips), .hip)
        XCTAssertEqual(LegJoint.from(.ankles), .ankle)
        XCTAssertNil(LegJoint.from(.back))
        XCTAssertNil(LegJoint.from(.none))
        XCTAssertEqual(LegJoint.injured(from: [.knees, .back]), [.knee])
    }

    // MARK: - Exclusion (Q4)

    func test_eligible_excludesInjuredJoint() {
        let unlock = LevelUpUnlock(injuredJoints: [.knee], comfortableWithBodyweight: true, unlockedAt: Date())
        let eligible = ExerciseSelector.eligible(bank: bank, unlock: unlock)
        XCTAssertFalse(eligible.contains { $0.impactedJoints.contains(.knee) })
        // Jump rope (ankle only) survives a knee injury.
        XCTAssertTrue(eligible.contains { $0.id == "jump_rope" })
    }

    func test_eligible_comfortSubsetIntersected() {
        let unlock = LevelUpUnlock(injuredJoints: [], comfortableWithBodyweight: false,
                                   approvedExerciseIDs: ["jump_rope", "squat_jumps"], unlockedAt: Date())
        let eligible = ExerciseSelector.eligible(bank: bank, unlock: unlock)
        XCTAssertEqual(Set(eligible.map(\.id)), ["jump_rope", "squat_jumps"])
    }

    func test_eligible_nilUnlock_allBank() {
        XCTAssertEqual(ExerciseSelector.eligible(bank: bank, unlock: nil).count, 8)
    }

    // MARK: - Selection (Q2)

    func test_sequence_noRepeatUntilExhausted() {
        let seq = ExerciseSelector.sequence(eligible: bank, count: 6, seed: 42)
        XCTAssertEqual(seq.count, 6)
        XCTAssertEqual(Set(seq.map(\.id)).count, 6)   // 6 distinct from a bank of 8
    }

    func test_sequence_reshufflesPastPool() {
        let seq = ExerciseSelector.sequence(eligible: bank, count: 11, seed: 7)
        XCTAssertEqual(seq.count, 11)
        // First 8 distinct (one full cycle), then reshuffle.
        XCTAssertEqual(Set(seq.prefix(8).map(\.id)).count, 8)
    }

    func test_sequence_emptyPool_returnsEmpty() {
        XCTAssertTrue(ExerciseSelector.sequence(eligible: [], count: 6, seed: 1).isEmpty)
    }

    func test_sequence_deterministicForSeed() {
        let a = ExerciseSelector.sequence(eligible: bank, count: 6, seed: 99).map(\.id)
        let b = ExerciseSelector.sequence(eligible: bank, count: 6, seed: 99).map(\.id)
        XCTAssertEqual(a, b)
    }

    // MARK: - Continuous timeline (§2.1)

    func test_continuous_blocksHaveExercise_exceptBlock7() {
        let ex = ExerciseSelector.sequence(eligible: bank, count: 6, seed: 1)
        let p = LevelUpProtocolBuilder.build(type: .continuous, exercises: ex)
        XCTAssertEqual(p.phases.filter { $0.kind == .exercise }.count, 6)  // Blocks 1–6
        // Block 7 (last scored block) is a pure 300s run, no following exercise.
        let runBlocks = p.phases.filter { $0.kind == .block || $0.kind == .warmup }
        XCTAssertEqual(runBlocks.last?.durationSec, 300)
        XCTAssertNil(runBlocks.last?.exercise)
    }

    func test_continuous_exercisePhasesNotScored() {
        let ex = ExerciseSelector.sequence(eligible: bank, count: 6, seed: 1)
        let p = LevelUpProtocolBuilder.build(type: .continuous, exercises: ex)
        XCTAssertFalse(PhaseKind.exercise.isScored)
        // Training = 6×230 run + 1×300 (Block 7) warmup/block run = 1680.
        XCTAssertEqual(p.trainingDurationSec, 6 * 230 + 300)
    }

    // MARK: - HIIT timeline (§2.2)

    func test_hiit_structure() {
        let ex = ExerciseSelector.sequence(eligible: bank, count: 11, seed: 3)
        let p = LevelUpProtocolBuilder.build(type: .hiit, exercises: ex)
        XCTAssertEqual(p.phases.filter { $0.kind == .work }.count, 10)       // 10 rounds
        XCTAssertEqual(p.phases.filter { $0.kind == .exercise }.count, 11)   // block + 10 rounds
        XCTAssertEqual(p.phases.filter { $0.kind == .warmup }.count, 1)
        // Each HIIT exercise paces 20 reps.
        XCTAssertTrue(p.phases.filter { $0.kind == .exercise }.allSatisfy { $0.exerciseReps == 20 })
    }

    func test_exerciseMode_timing() {
        XCTAssertEqual(ExerciseMode.bilateral.durationSec, 30)
        XCTAssertEqual(ExerciseMode.bilateral.reps, 15)
        XCTAssertEqual(ExerciseMode.unilateral.durationSec, 32)
        XCTAssertEqual(ExerciseMode.unilateral.reps, 8)
        XCTAssertTrue(ExerciseMode.unilateral.perLeg)
    }

    // MARK: - Persistence

    func test_levelUpUnlock_codableRoundTrip() throws {
        var profile = UserProfileV2.fixture
        profile.levelUpUnlock = LevelUpUnlock(injuredJoints: [.knee], comfortableWithBodyweight: false,
                                              approvedExerciseIDs: ["jump_rope"], unlockedAt: Date(timeIntervalSince1970: 1000))
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfileV2.self, from: data)
        XCTAssertEqual(decoded.levelUpUnlock?.injuredJoints, [.knee])
        XCTAssertEqual(decoded.levelUpUnlock?.approvedExerciseIDs, ["jump_rope"])
    }
}
