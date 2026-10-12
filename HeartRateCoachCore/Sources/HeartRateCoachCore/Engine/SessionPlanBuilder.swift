import Foundation

/// One row of the client session-plan PDF (§K).
public struct SessionPlanRow: Sendable, Equatable {
    public let sessionNumber: Int        // 1-based
    public let type: WorkoutType
    public let focus: String
    public let intensity: String
    public let durationMin: Int
}

/// Builds the per-stage client session plan (§K / FR-11, Q9). Pure — projects the
/// deterministic ratio schedule (P3) across all 60 sessions for the user's classification.
public enum SessionPlanBuilder {

    public static func plan(stage: TrainingStage, profile: UserProfileV2) -> [SessionPlanRow] {
        let exp = profile.fitnessExperience
        let goals = profile.goals
        let lean = profile.mentalityLean
        return (0..<ProgressionEngine.sessionsPerStage).map { n in
            let type = ProgressionEngine.plannedType(experience: exp, goals: goals, lean: lean, sessionIndex: n)
            let sub = n / ProgressionEngine.sessionsPerSubPhase       // 0,1,2
            return SessionPlanRow(
                sessionNumber: n + 1,
                type: type,
                focus: focus(type: type, subPhase: sub, stage: stage),
                intensity: intensity(type: type, subPhase: sub),
                durationMin: durationMin(stage: stage, type: type))
        }
    }

    /// Frequency-based projected completion (§B), framed toward the next stage.
    public static func projectedCompletionNote(frequencyPerWeek freq: Int, stage: TrainingStage) -> String {
        let estimate: String
        switch freq {
        case 5...: estimate = "about 3 months"
        case 4: estimate = "about 3.5 months"
        default: estimate = "about 4.5–5 months"
        }
        let next = stage.next.map { " Then you'll unlock \($0.displayName)." } ?? ""
        return "At \(freq)× per week, you'll complete \(stage.displayName)'s 60 sessions in \(estimate).\(next)"
    }

    // MARK: - Row content (rotating "what to expect" pairs)

    private static func focus(type: WorkoutType, subPhase: Int, stage: TrainingStage) -> String {
        let base = type == .hiit ? "Intervals — push and recover" : "Steady aerobic effort"
        let phase = ["build your base", "raise the work", "peak effort"][min(2, subPhase)]
        return "\(base); \(phase)"
    }
    private static func intensity(type: WorkoutType, subPhase: Int) -> String {
        type == .hiit ? "Hard intervals (Zone 3–4)" : "Moderate (Zone 2–3)"
    }
    private static func durationMin(stage: TrainingStage, type: WorkoutType) -> Int {
        37   // ~35 training + cooldown; HIIT Shape runs ~37:10 — rounded for the plan
    }
}
