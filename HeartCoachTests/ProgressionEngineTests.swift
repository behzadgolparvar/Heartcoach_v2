import XCTest
import HeartRateCoachCore

/// BR-3-1..11 — track resolution, assignment, advancement, relapse (Q5=B), minimum walk.
final class ProgressionEngineTests: XCTestCase {

    // MARK: - Helpers

    private func mentality(_ lean: MentalityLean) -> Mentality {
        switch lean {
        case .outcome: return Mentality(motivationDriver: .outcome, missedResponse: .goal, routinePreference: .variety)
        case .process: return Mentality(motivationDriver: .process, missedResponse: .habit, routinePreference: .fixed)
        case .mixed:   return Mentality(motivationDriver: .outcome, missedResponse: .habit, routinePreference: .fixed)
        }
    }

    private func profile(exp: FitnessExperience, goals: Set<TrainingGoal>,
                         lean: MentalityLean, done: Int,
                         lastDate: Date? = nil) -> UserProfileV2 {
        let program = ProgramState(
            currentStage: .foundation,
            stageProgress: [.foundation: StageProgress(stage: .foundation, sessionsCompleted: done)],
            lastCountedSessionDate: lastDate)
        return UserProfileV2(
            age: 30, gender: .preferNotToSay, unitsPreference: .metric, restingHR: 60,
            goals: goals, fitnessExperience: exp, mentality: mentality(lean),
            program: program,
            schedule: Schedule(sessionLengthMin: 35, frequencyPerWeek: 3),
            consent: Consent(healthDataConsent: true, remindersConsent: true, consentedAt: nil, consentVersion: "1.0"),
            v2Completed: true)
    }

    // MARK: - Track resolution (Q2)

    func test_trackResolution() {
        XCTAssertEqual(ProgressionTrack.resolve(experience: .beginner, goals: [.fastWeightLoss, .routine]), .beginnerFastWeightLoss)
        XCTAssertEqual(ProgressionTrack.resolve(experience: .beginner, goals: [.routine]), .beginnerRoutineCardio)
        XCTAssertEqual(ProgressionTrack.resolve(experience: .intermediate, goals: [.fastWeightLoss]), .intermediate)
        XCTAssertEqual(ProgressionTrack.resolve(experience: .advanced, goals: []), .advanced)
    }

    // MARK: - Assignment (Q1/Q3)

    func test_beginnerFWL_outcome_subPhase1_cycle() {
        // 1:2 → [hiit, cont, cont]
        let types = (0..<3).map { ProgressionEngine.assign(profile: profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: $0)).type }
        XCTAssertEqual(types, [.hiit, .continuous, .continuous])
    }

    func test_advanced_outcome_subPhase1_cycle() {
        // 2:1 → [hiit, hiit, cont]
        let types = (0..<3).map { ProgressionEngine.assign(profile: profile(exp: .advanced, goals: [], lean: .outcome, done: $0)).type }
        XCTAssertEqual(types, [.hiit, .hiit, .continuous])
    }

    func test_subPhaseBoundary_usesNextRatio() {
        // Beginner FWL outcome SP2 (done 20) = 1:1 → [hiit, cont]; session 21.
        let a = ProgressionEngine.assign(profile: profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: 20))
        XCTAssertEqual(a.subPhase, 1)
        XCTAssertEqual(a.sessionNumber, 21)
        XCTAssertEqual(a.type, .hiit)
    }

    func test_routineCardio_outcome_oneInFour() {
        let types = (0..<4).map { ProgressionEngine.assign(profile: profile(exp: .beginner, goals: [.routine], lean: .outcome, done: $0)).type }
        XCTAssertEqual(types, [.hiit, .continuous, .continuous, .continuous])
    }

    func test_routineCardio_process_pureContinuous() {
        let types = (0..<5).map { ProgressionEngine.assign(profile: profile(exp: .beginner, goals: [.routine], lean: .process, done: $0)).type }
        XCTAssertEqual(types, Array(repeating: WorkoutType.continuous, count: 5))
    }

    func test_stageComplete_at60() {
        let a = ProgressionEngine.assign(profile: profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: 60))
        XCTAssertTrue(a.isStageComplete)
        XCTAssertEqual(a.sessionNumber, 60)
        XCTAssertEqual(a.subPhase, 2)
    }

    // MARK: - Advancement (Q4)

    func test_advance_countsScoredTraining() {
        let p = profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: 5).program!
        let out = ProgressionEngine.advance(program: p, sessionFlag: "continuous", trainingDurationSec: 2100, date: Date())
        XCTAssertEqual(out.currentProgress.sessionsCompleted, 6)
        XCTAssertNotNil(out.lastCountedSessionDate)
    }

    func test_advance_excludesMinimumAndShortSessions() {
        let p = profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: 5).program!
        XCTAssertEqual(ProgressionEngine.advance(program: p, sessionFlag: "minimum_walk", trainingDurationSec: 900, date: Date()).currentProgress.sessionsCompleted, 5)
        XCTAssertEqual(ProgressionEngine.advance(program: p, sessionFlag: "continuous", trainingDurationSec: 600, date: Date()).currentProgress.sessionsCompleted, 5)
    }

    func test_advance_clampsAt60() {
        let p = profile(exp: .advanced, goals: [], lean: .outcome, done: 60).program!
        XCTAssertEqual(ProgressionEngine.advance(program: p, sessionFlag: "hiit", trainingDurationSec: 1200, date: Date()).currentProgress.sessionsCompleted, 60)
    }

    // MARK: - Relapse (Q5=B)

    private func daysAgo(_ d: Int) -> Date { Date().addingTimeInterval(-Double(d) * 86_400) }

    func test_relapse_bands() {
        func after(gap: Int, done: Int) -> (RelapseBand, Int) {
            let p = profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: done, lastDate: daysAgo(gap)).program!
            let (np, outcome) = ProgressionEngine.applyRelapse(program: p, now: Date())
            return (outcome.band, np.currentProgress.sessionsCompleted)
        }
        XCTAssertEqual(after(gap: 3, done: 22).0, .none)
        XCTAssertEqual(after(gap: 10, done: 22).1, 19)   // -3, crosses into SP1 (Q5=B plain subtraction)
        XCTAssertEqual(after(gap: 18, done: 22).1, 17)   // -5
        XCTAssertEqual(after(gap: 25, done: 22).1, 14)   // -8
        XCTAssertEqual(after(gap: 45, done: 40).1, 0)    // reset to start of stage
    }

    func test_relapse_onlyOncePerGap() {
        let p = profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: 22, lastDate: daysAgo(18)).program!
        let (p1, o1) = ProgressionEngine.applyRelapse(program: p, now: Date())
        XCTAssertEqual(o1.band, .pushBack5)
        let (p2, o2) = ProgressionEngine.applyRelapse(program: p1, now: Date())
        XCTAssertEqual(o2.band, .none)                    // clock re-stamped; no double penalty
        XCTAssertEqual(p2.currentProgress.sessionsCompleted, 17)
    }

    func test_relapse_noBaseline_isNone() {
        let p = profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: 10).program!
        XCTAssertEqual(ProgressionEngine.applyRelapse(program: p, now: Date()).1.band, .none)
    }

    // MARK: - Minimum walk (Q7)

    func test_minimumWalk_stampsDate_noAdvance() {
        let p = profile(exp: .beginner, goals: [.fastWeightLoss], lean: .outcome, done: 10).program!
        let out = ProgressionEngine.registerMinimumWalk(program: p, now: Date())
        XCTAssertEqual(out.currentProgress.sessionsCompleted, 10)
        XCTAssertNotNil(out.lastCountedSessionDate)
    }
}
