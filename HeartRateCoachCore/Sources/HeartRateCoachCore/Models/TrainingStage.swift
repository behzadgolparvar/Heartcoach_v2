import Foundation

/// The four training stages of the v5 program (spec §1). Each stage has its own
/// 60-session counter and 3 sub-phases of 20. `maintain` is defined for
/// completeness but is undesigned/out of scope this cycle (no protocols).
public enum TrainingStage: String, Codable, Sendable, CaseIterable, Comparable {
    case foundation
    case levelUp = "level_up"
    case shape
    case maintain

    private var order: Int {
        switch self {
        case .foundation: return 0
        case .levelUp: return 1
        case .shape: return 2
        case .maintain: return 3
        }
    }

    public static func < (lhs: TrainingStage, rhs: TrainingStage) -> Bool {
        lhs.order < rhs.order
    }

    /// The next stage in the program, or nil at the end (`maintain`).
    public var next: TrainingStage? {
        switch self {
        case .foundation: return .levelUp
        case .levelUp: return .shape
        case .shape: return .maintain
        case .maintain: return nil
        }
    }

    public var displayName: String {
        switch self {
        case .foundation: return "Foundation"
        case .levelUp: return "Level Up"
        case .shape: return "Shape"
        case .maintain: return "Maintain"
        }
    }
}
