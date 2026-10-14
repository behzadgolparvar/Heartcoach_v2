import Foundation

/// The user's per-session Shape choice (§Phase 3): Option A/B and, for B, the
/// two ranked muscle groups (priority + secondary).
public struct ShapeSessionChoice: Sendable, Equatable {
    public let option: ShapeOption          // .plyometric = Option A, .weights = Option B
    public let priority: MuscleGroup?       // Option B only
    public let secondary: MuscleGroup?      // Option B only

    public init(option: ShapeOption, priority: MuscleGroup? = nil, secondary: MuscleGroup? = nil) {
        self.option = option
        self.priority = priority
        self.secondary = secondary
    }

    /// Option A needs no muscles; Option B needs exactly 2 distinct, ordered (BR-5-2).
    public var isValid: Bool {
        switch option {
        case .plyometric: return true
        case .weights:
            guard let p = priority, let s = secondary else { return false }
            return p != s
        }
    }
}
