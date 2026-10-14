import Foundation

/// Shape-stage (training stage 3) placeholders. Defined now as the data contract
/// (Q6 context); the selection logic lands in Phase 5. Unused until then.

/// Daily choice in the Shape stage: Option A (plyometric) or Option B (weights).
public enum ShapeOption: String, Codable, Sendable, CaseIterable {
    case plyometric
    case weights

    public var displayName: String {
        switch self {
        case .plyometric: return "Option A — Plyometric"
        case .weights: return "Option B — Weights"
        }
    }
}

/// Muscle groups for Shape-stage weight training (standing free-weight banks, §G)
/// and leg work. Used for muscle-group selection + priority in Phase 5.
public enum MuscleGroup: String, Codable, Sendable, CaseIterable {
    case chest, back, shoulders, arms, abs, legs

    public var displayName: String { rawValue.capitalized }
}
