import Foundation

/// A HIIT : Continuous ratio for a sub-phase (spec §B).
public struct SessionRatio: Sendable, Equatable {
    public let hiit: Int
    public let continuous: Int

    public init(_ hiit: Int, _ continuous: Int) {
        self.hiit = hiit
        self.continuous = continuous
    }

    /// Deterministic repeating pattern for the ratio (Q1=A), HIIT front-loaded
    /// within each cycle group: 1:2 → [hiit, cont, cont]; 2:1 → [hiit, hiit, cont].
    public var cycle: [WorkoutType] {
        Array(repeating: WorkoutType.hiit, count: hiit)
            + Array(repeating: WorkoutType.continuous, count: continuous)
    }

    /// The type for a 0-based session index within the sub-phase.
    public func type(forSessionIndex i: Int) -> WorkoutType {
        let c = cycle
        guard !c.isEmpty else { return .continuous }
        return c[i % c.count]
    }
}
