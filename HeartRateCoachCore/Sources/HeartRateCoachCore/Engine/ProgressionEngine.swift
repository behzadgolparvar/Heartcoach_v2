import Foundation

/// Assigns today's Foundation session and advances/relapses the counter (spec §B/§C).
/// Pure — all time is injected, nothing is logged (SECURITY-03).
public enum ProgressionEngine {

    public static let sessionsPerStage = 60
    public static let sessionsPerSubPhase = 20
    private static let minScoredTrainingSec = 1200   // ≥20 min (§J)

    // MARK: - Assignment (BR-3-1..4, 11)

    public static func assign(profile: UserProfileV2) -> SessionAssignment {
        let program = profile.program ?? .newUser()
        let n = program.currentProgress.sessionsCompleted
        let track = ProgressionTrack.resolve(experience: profile.fitnessExperience, goals: profile.goals)
        let lean = profile.mentalityLean
        let complete = n >= sessionsPerStage
        let sub = min(2, n / sessionsPerSubPhase)

        let ratio = ProgressionTables.ratio(track: track, lean: lean, subPhase: sub)
        let type = assignType(track: track, lean: lean, sessionsCompleted: n, ratio: ratio)

        return SessionAssignment(
            type: type,
            sessionNumber: min(n + 1, sessionsPerStage),
            subPhase: sub,
            ratio: ratio,
            isStageComplete: complete)
    }

    private static func assignType(track: ProgressionTrack, lean: MentalityLean,
                                   sessionsCompleted n: Int, ratio: SessionRatio?) -> WorkoutType {
        if track == .beginnerRoutineCardio {
            // Continuous only; outcome-lean gets HIIT every 4th session (Q3=A).
            if lean == .outcome, n % 4 == 0 { return .hiit }
            return .continuous
        }
        guard let ratio else { return .continuous }
        return ratio.type(forSessionIndex: n % sessionsPerSubPhase)
    }

    /// Projects the assigned workout type for a 0-based session index within a stage,
    /// for a given classification — used by the client session-plan PDF (BR-6-13).
    public static func plannedType(experience: FitnessExperience, goals: Set<TrainingGoal>,
                                   lean: MentalityLean, sessionIndex n: Int) -> WorkoutType {
        let track = ProgressionTrack.resolve(experience: experience, goals: goals)
        let sub = min(2, n / sessionsPerSubPhase)
        let ratio = ProgressionTables.ratio(track: track, lean: lean, subPhase: sub)
        return assignType(track: track, lean: lean, sessionsCompleted: n, ratio: ratio)
    }

    // MARK: - Advancement (BR-3-5/6)

    public static func advance(program: ProgramState, sessionFlag: String,
                               trainingDurationSec: Int, date: Date) -> ProgramState {
        let qualifies = (sessionFlag == WorkoutType.continuous.rawValue || sessionFlag == WorkoutType.hiit.rawValue)
            && trainingDurationSec >= minScoredTrainingSec
        guard qualifies else { return program }
        var updated = program
        let p = updated.currentProgress
        let newCount = min(sessionsPerStage, p.sessionsCompleted + 1)
        updated.stageProgress[updated.currentStage] = StageProgress(stage: updated.currentStage, sessionsCompleted: newCount)
        updated.lastCountedSessionDate = date
        return updated
    }

    // MARK: - Relapse (§C, Q5=B — spec-literal)

    public static func applyRelapse(program: ProgramState, now: Date) -> (ProgramState, RelapseOutcome) {
        let before = program.currentProgress.sessionsCompleted
        guard let last = program.lastCountedSessionDate else {
            return (program, RelapseOutcome(band: .none, sessionsBefore: before, sessionsAfter: before))
        }
        let gapDays = Int(now.timeIntervalSince(last) / 86_400)
        let band = RelapseBand.from(gapDays: max(0, gapDays))
        guard band != .none else {
            return (program, RelapseOutcome(band: .none, sessionsBefore: before, sessionsAfter: before))
        }
        let after = band == .resetToStart ? 0 : max(0, before - band.pushBack)
        var updated = program
        updated.stageProgress[updated.currentStage] = StageProgress(stage: updated.currentStage, sessionsCompleted: after)
        updated.lastCountedSessionDate = now   // once-per-gap: re-opening finds gap ≈ 0
        return (updated, RelapseOutcome(band: band, sessionsBefore: before, sessionsAfter: after))
    }

    // MARK: - Non-negotiable minimum (§I, BR-3-9)

    /// Resets the relapse clock without advancing progression.
    public static func registerMinimumWalk(program: ProgramState, now: Date) -> ProgramState {
        var updated = program
        updated.lastCountedSessionDate = now
        return updated
    }
}
