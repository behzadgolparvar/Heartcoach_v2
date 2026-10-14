import XCTest
import HeartRateCoachCore

/// BR-5-1..10 — Shape alternation, planner (Legs rule), protocol timelines, banks.
final class ShapeTests: XCTestCase {

    // MARK: - Banks

    func test_weightBanks_sixPerMuscle_legsEmpty() {
        for m in [MuscleGroup.chest, .back, .shoulders, .arms, .abs] {
            XCTAssertEqual(WeightExerciseBank.exercises(for: m).count, 6, "\(m)")
        }
        XCTAssertTrue(WeightExerciseBank.exercises(for: .legs).isEmpty)
    }

    // MARK: - Alternation (Q5)

    func test_continuousAlternation_4_2() {
        XCTAssertEqual(ShapeAlternation.continuous,
                       [.priority, .secondary, .priority, .secondary, .priority, .priority])
        let priorityCount = ShapeAlternation.continuous.filter { $0 == .priority }.count
        XCTAssertEqual(priorityCount, 4)
    }

    func test_hiitAlternation_6_5() {
        let roles = ShapeAlternation.hiit()
        XCTAssertEqual(roles.count, 11)
        XCTAssertEqual(roles.filter { $0 == .priority }.count, 6)   // even indices 0,2,4,6,8,10
        XCTAssertEqual(roles.filter { $0 == .secondary }.count, 5)
        XCTAssertEqual(roles[0], .priority)
        XCTAssertEqual(roles[10], .priority)
    }

    // MARK: - Planner (Q2/Q4/Q6)

    func test_optionB_rolesMapToMuscles_andLegsRule() {
        let choice = ShapeSessionChoice(option: .weights, priority: .chest, secondary: .legs)
        let plan = ShapeExercisePlanner.plan(choice: choice, type: .continuous, legUnlock: nil, seed: 1)
        XCTAssertEqual(plan.count, 6)
        // Pattern [P,S,P,S,P,P] → muscles [chest, legs, chest, legs, chest, chest]
        XCTAssertEqual(plan.map(\.muscle), [.chest, .legs, .chest, .legs, .chest, .chest])
        // Legs phases are plyometric (20 reps, a leg exercise); chest phases are weights (30 reps).
        for p in plan {
            if p.muscle == .legs { XCTAssertEqual(p.reps, 20); XCTAssertNotNil(p.legExercise) }
            else { XCTAssertEqual(p.reps, 30); XCTAssertNil(p.legExercise) }
        }
    }

    func test_optionA_allLegs20Reps() {
        let choice = ShapeSessionChoice(option: .plyometric)
        let plan = ShapeExercisePlanner.plan(choice: choice, type: .hiit, legUnlock: nil, seed: 2)
        XCTAssertEqual(plan.count, 11)
        XCTAssertTrue(plan.allSatisfy { $0.muscle == .legs && $0.reps == 20 && $0.legExercise != nil })
    }

    func test_planner_injuryExcludesLegExercises() {
        let unlock = LevelUpUnlock(injuredJoints: [.knee], comfortableWithBodyweight: true, unlockedAt: Date())
        let choice = ShapeSessionChoice(option: .plyometric)
        let plan = ShapeExercisePlanner.plan(choice: choice, type: .continuous, legUnlock: unlock, seed: 3)
        XCTAssertFalse(plan.contains { $0.legExercise?.impactedJoints.contains(.knee) ?? false })
    }

    func test_planner_deterministicForSeed() {
        let choice = ShapeSessionChoice(option: .weights, priority: .back, secondary: .arms)
        let a = ShapeExercisePlanner.plan(choice: choice, type: .continuous, legUnlock: nil, seed: 9).map(\.name)
        let b = ShapeExercisePlanner.plan(choice: choice, type: .continuous, legUnlock: nil, seed: 9).map(\.name)
        XCTAssertEqual(a, b)
    }

    // MARK: - Choice validation (Q2)

    func test_choiceValidation() {
        XCTAssertTrue(ShapeSessionChoice(option: .plyometric).isValid)
        XCTAssertTrue(ShapeSessionChoice(option: .weights, priority: .chest, secondary: .arms).isValid)
        XCTAssertFalse(ShapeSessionChoice(option: .weights, priority: .chest, secondary: .chest).isValid)
        XCTAssertFalse(ShapeSessionChoice(option: .weights, priority: .chest).isValid)
    }

    // MARK: - Protocol timelines (Q7)

    func test_continuous_structure() {
        let plan = ShapeExercisePlanner.plan(
            choice: ShapeSessionChoice(option: .weights, priority: .chest, secondary: .back),
            type: .continuous, legUnlock: nil, seed: 1)
        let p = ShapeProtocolBuilder.build(type: .continuous, planned: plan)
        XCTAssertEqual(p.phases.filter { $0.kind == .exercise }.count, 6)
        // Block 1 warm-up run = 230s; a pure-run Block 7 of 240s with no following exercise.
        XCTAssertEqual(p.phases.first { $0.kind == .warmup }?.durationSec, 230)
        let runs = p.phases.filter { $0.kind == .block || $0.kind == .warmup }
        XCTAssertEqual(runs.last?.durationSec, 240)
        // Training (scored) = 230 + 5×170 + 240 = 1320.
        XCTAssertEqual(p.trainingDurationSec, 1320)
    }

    func test_hiit_structure_11exercisePhases() {
        let plan = ShapeExercisePlanner.plan(
            choice: ShapeSessionChoice(option: .weights, priority: .chest, secondary: .back),
            type: .hiit, legUnlock: nil, seed: 1)
        let p = ShapeProtocolBuilder.build(type: .hiit, planned: plan)
        XCTAssertEqual(p.phases.filter { $0.kind == .exercise }.count, 11)
        XCTAssertEqual(p.phases.filter { $0.kind == .work }.count, 10)
        // Training (scored) = warm-up 180 + 10×50 = 680.
        XCTAssertEqual(p.trainingDurationSec, 680)
    }

    // MARK: - Persistence

    func test_shapeUnlock_codableRoundTrip() throws {
        var profile = UserProfileV2.fixture
        profile.shapeUnlock = ShapeUnlock(equipmentPreference: .weights, focusAreas: [.chest, .legs],
                                          acknowledgedLevelUpPain: true, unlockedAt: Date(timeIntervalSince1970: 500))
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfileV2.self, from: data)
        XCTAssertEqual(decoded.shapeUnlock?.equipmentPreference, .weights)
        XCTAssertEqual(decoded.shapeUnlock?.focusAreas, [.chest, .legs])
    }
}
