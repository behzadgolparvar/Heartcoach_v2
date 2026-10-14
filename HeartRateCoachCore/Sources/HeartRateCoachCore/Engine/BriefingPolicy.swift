import Foundation

/// Decides whether the ~1-minute pre-session briefing is mandatory (spec §D, Q4=A).
/// Mandatory for the first 4 **scored** sessions of a workout type within the
/// current training stage, skippable after (BR-2-11). The count is derived by the
/// caller from session history + `StageProgress` — no dedicated counter stored.
public enum BriefingPolicy {
    public static let mandatoryThreshold = 4

    /// - Parameter priorScoredSessionsOfTypeThisStage: completed scored sessions of
    ///   this workout type in the current stage (excludes walk_fallback and <20-min discards).
    public static func isMandatory(priorScoredSessionsOfTypeThisStage count: Int) -> Bool {
        count < mandatoryThreshold
    }
}
