import Foundation

/// Pure classification resolver for the v5 experience model (spec §A).
/// Single source of truth: combines Q1 (training history, authoritative),
/// Q2 (self-select), and the GLP-1/Ozempic flag into a resolved tier.
///
/// No I/O and no value-emitting logging — inputs/outputs are health data
/// (SECURITY-03, BR-1b-10).
public enum ExperienceResolver {

    public struct Result: Sendable, Equatable {
        /// The tier to train at.
        public let resolved: FitnessExperience
        /// True when Q1 and Q2 disagreed at the extremes (matrix override).
        /// Reflects the matrix only — independent of the Ozempic override — so
        /// research data captures the Q1/Q2 disagreement either way.
        public let mismatch: Bool
    }

    /// BR-1b-2 (resolution matrix) + BR-1b-3 (Ozempic override).
    /// - Parameters:
    ///   - q1: training history (authoritative).
    ///   - q2: self-selected tier.
    ///   - onGLP1: whether the user is on GLP-1 / anti-obesity therapy.
    public static func resolve(q1: TrainingHistory,
                               q2: FitnessExperience,
                               onGLP1: Bool) -> Result {
        let (matrixResolved, mismatch) = matrix(q1Tier: q1.mappedTier, q2: q2)
        let resolved = onGLP1 ? .beginner : matrixResolved
        return Result(resolved: resolved, mismatch: mismatch)
    }

    /// BR-1b-2 — only the two extreme-disagreement pairs override Q1;
    /// every other combination lets Q1 win (mismatch = false).
    private static func matrix(q1Tier: FitnessExperience,
                               q2: FitnessExperience) -> (FitnessExperience, Bool) {
        switch (q1Tier, q2) {
        case (.beginner, .advanced), (.advanced, .beginner):
            return (.intermediate, true)
        default:
            return (q1Tier, false)
        }
    }
}
