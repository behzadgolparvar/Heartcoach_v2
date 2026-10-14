import Foundation

/// The engine's proposal for the next Foundation session (spec §B).
public struct SessionAssignment: Sendable, Equatable {
    public let type: WorkoutType
    /// 1-based session number within the stage (= sessionsCompleted + 1), capped at 60.
    public let sessionNumber: Int
    /// Sub-phase index 0–2.
    public let subPhase: Int
    /// The ratio in force (nil for Beginner Routine/Cardio).
    public let ratio: SessionRatio?
    /// True once the stage's 60 sessions are complete (Q8).
    public let isStageComplete: Bool

    public init(type: WorkoutType, sessionNumber: Int, subPhase: Int,
                ratio: SessionRatio?, isStageComplete: Bool) {
        self.type = type
        self.sessionNumber = sessionNumber
        self.subPhase = subPhase
        self.ratio = ratio
        self.isStageComplete = isStageComplete
    }
}
