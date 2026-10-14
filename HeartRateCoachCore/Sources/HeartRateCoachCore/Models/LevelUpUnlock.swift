import Foundation

/// The user's answers to the Level Up unlock questions (§E), captured once on
/// entering Level Up and used to filter the exercise bank (BR-4-3/7).
public struct LevelUpUnlock: Codable, Sendable, Equatable {
    /// Injured leg joints (pre-filled from P1b `jointIssues`, user-confirmed).
    public var injuredJoints: Set<LegJoint>
    /// §E Q2 — comfortable doing bodyweight squats/lunges.
    public var comfortableWithBodyweight: Bool
    /// When not comfortable, the user's hand-picked approved exercise ids; nil = all eligible.
    public var approvedExerciseIDs: Set<String>?
    public var unlockedAt: Date

    public init(injuredJoints: Set<LegJoint>, comfortableWithBodyweight: Bool,
                approvedExerciseIDs: Set<String>? = nil, unlockedAt: Date) {
        self.injuredJoints = injuredJoints
        self.comfortableWithBodyweight = comfortableWithBodyweight
        self.approvedExerciseIDs = approvedExerciseIDs
        self.unlockedAt = unlockedAt
    }

    /// True when an injury caution should be shown (§E, BR-4-6).
    public var hasInjury: Bool { !injuredJoints.isEmpty }
}
