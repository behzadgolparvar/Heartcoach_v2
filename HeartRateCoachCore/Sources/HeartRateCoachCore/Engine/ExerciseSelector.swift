import Foundation

/// Selects leg exercises for a Level Up session: injury/comfort exclusion (§E)
/// + seeded no-repeat rotation (§G). Pure — all randomness is seeded (Q2/Q4).
public enum ExerciseSelector {

    /// BR-4-3 — exercises whose joints don't intersect any injured joint, and
    /// (if the user pre-selected a subset) that are in the approved set.
    public static func eligible(bank: [LegExercise], unlock: LevelUpUnlock?) -> [LegExercise] {
        guard let unlock else { return bank }
        return bank.filter { ex in
            ex.impactedJoints.isDisjoint(with: unlock.injuredJoints)
                && (unlock.approvedExerciseIDs?.contains(ex.id) ?? true)
        }
    }

    /// BR-4-4/5 — `count` exercises drawn from the eligible pool via a seeded
    /// shuffle, without replacement; reshuffle on exhaustion. Empty pool → [].
    public static func sequence(eligible: [LegExercise], count: Int, seed: UInt64) -> [LegExercise] {
        guard count > 0, !eligible.isEmpty else { return [] }
        var rng = SeededGenerator(seed: seed)
        var result: [LegExercise] = []
        var pool: [LegExercise] = []
        while result.count < count {
            if pool.isEmpty { pool = shuffled(eligible, using: &rng) }
            result.append(pool.removeFirst())
        }
        return result
    }

    private static func shuffled(_ items: [LegExercise], using rng: inout SeededGenerator) -> [LegExercise] {
        var a = items
        // Fisher–Yates with the seeded generator (deterministic).
        for i in stride(from: a.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            a.swapAt(i, j)
        }
        return a
    }
}
