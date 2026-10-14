import Foundation

/// Per-stage progression record (spec §B). A stage runs 60 sessions across
/// 3 sub-phases of 20. P1b defines the data contract; the progression engine
/// (Phase 3) drives `sessionsCompleted`.
public struct StageProgress: Codable, Sendable, Equatable {
    public var stage: TrainingStage
    /// Completed sessions in this stage, 0…60.
    public var sessionsCompleted: Int

    public init(stage: TrainingStage, sessionsCompleted: Int = 0) {
        self.stage = stage
        self.sessionsCompleted = sessionsCompleted
    }

    /// BR-1b-8 — sub-phase index 0,1,2 (each covers 20 sessions); capped at 2.
    public var subPhase: Int { min(2, sessionsCompleted / 20) }

    /// True once all 60 sessions of the stage are complete.
    public var isStageComplete: Bool { sessionsCompleted >= 60 }
}
