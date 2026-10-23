import Foundation

/// One row of the client session-plan PDF (§K).
public struct SessionPlanRow: Sendable, Equatable {
    public let sessionNumber: Int        // 1-based
    public let type: WorkoutType
    public let focus: String
    public let intensity: String
    public let durationMin: Int

    public init(sessionNumber: Int, type: WorkoutType, focus: String, intensity: String, durationMin: Int) {
        self.sessionNumber = sessionNumber
        self.type = type
        self.focus = focus
        self.intensity = intensity
        self.durationMin = durationMin
    }
}

/// A run of consecutive sessions that share the same type/focus/intensity/duration —
/// a scannable "block" for the plan PDF instead of listing 60 near-identical rows.
public struct SessionPlanBlock: Sendable, Equatable {
    public let startSession: Int         // 1-based, inclusive
    public let endSession: Int
    public let type: WorkoutType
    public let focus: String
    public let intensity: String
    public let durationMin: Int

    public init(startSession: Int, endSession: Int, type: WorkoutType,
                focus: String, intensity: String, durationMin: Int) {
        self.startSession = startSession
        self.endSession = endSession
        self.type = type
        self.focus = focus
        self.intensity = intensity
        self.durationMin = durationMin
    }

    public var sessionsLabel: String {
        startSession == endSession ? "Session \(startSession)" : "Sessions \(startSession)–\(endSession)"
    }
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

    /// Groups the per-session rows into consecutive runs that share the same
    /// type/focus/intensity/duration — e.g. Foundation collapses to 3 blocks.
    public static func blocks(stage: TrainingStage, profile: UserProfileV2) -> [SessionPlanBlock] {
        group(plan(stage: stage, profile: profile))
    }

    public static func group(_ rows: [SessionPlanRow]) -> [SessionPlanBlock] {
        var blocks: [SessionPlanBlock] = []
        for row in rows {
            if let last = blocks.last,
               last.type == row.type, last.focus == row.focus,
               last.intensity == row.intensity, last.durationMin == row.durationMin {
                blocks[blocks.count - 1] = SessionPlanBlock(
                    startSession: last.startSession, endSession: row.sessionNumber,
                    type: last.type, focus: last.focus,
                    intensity: last.intensity, durationMin: last.durationMin)
            } else {
                blocks.append(SessionPlanBlock(
                    startSession: row.sessionNumber, endSession: row.sessionNumber,
                    type: row.type, focus: row.focus,
                    intensity: row.intensity, durationMin: row.durationMin))
            }
        }
        return blocks
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
