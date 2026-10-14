import Foundation

/// How a leg exercise is performed — drives phase duration + rep target (§2.1).
public enum ExerciseMode: String, Codable, Sendable, Equatable {
    case bilateral   // both legs together — 30s / 15 reps
    case unilateral  // one leg at a time — 32s / 8 reps per leg (switch halfway)

    public var durationSec: Int { self == .bilateral ? 30 : 32 }
    /// Reps per leg for unilateral; total reps for bilateral.
    public var reps: Int { self == .bilateral ? 15 : 8 }
    public var perLeg: Bool { self == .unilateral }
}

/// Lower-body joints a leg exercise stresses — used for injury exclusion (§E).
public enum LegJoint: String, Codable, Sendable, Equatable, CaseIterable {
    case knee, hip, ankle

    /// Maps a P1b `JointIssue` to the leg joint it affects (back/none → nil).
    public static func from(_ issue: JointIssue) -> LegJoint? {
        switch issue {
        case .knees: return .knee
        case .hips: return .hip
        case .ankles: return .ankle
        case .back, .none: return nil
        }
    }

    /// The set of leg joints implied by a user's reported joint issues.
    public static func injured(from issues: Set<JointIssue>) -> Set<LegJoint> {
        Set(issues.compactMap { from($0) })
    }
}

/// A standing bodyweight leg exercise (§G).
public struct LegExercise: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let mode: ExerciseMode
    /// Joints this move stresses (for injury exclusion, BR-4-3). Tags are defaults
    /// pending collaborator confirmation (safety-relevant).
    public let impactedJoints: Set<LegJoint>

    public init(id: String, name: String, mode: ExerciseMode, impactedJoints: Set<LegJoint>) {
        self.id = id
        self.name = name
        self.mode = mode
        self.impactedJoints = impactedJoints
    }
}
