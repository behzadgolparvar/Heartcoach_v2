import Foundation

/// Priority/secondary role for a Shape exercise phase.
public enum MuscleRole: Sendable, Equatable { case priority, secondary }

/// The phase-role alternation patterns (§3.1/§3.2, Q5).
public enum ShapeAlternation {
    /// Continuous — 6 phases, 4-2 split (priority gets 4).
    public static let continuous: [MuscleRole] = [.priority, .secondary, .priority, .secondary, .priority, .priority]
    /// HIIT — 11 phases (0–10), 6-5 split (even = priority).
    public static func hiit() -> [MuscleRole] {
        (0..<11).map { $0 % 2 == 0 ? .priority : .secondary }
    }

    public static func roles(for type: WorkoutType) -> [MuscleRole] {
        type == .hiit ? hiit() : continuous
    }
}

/// A resolved exercise for one Shape exercise phase.
public struct PlannedExercise: Sendable, Equatable {
    public let name: String
    public let muscle: MuscleGroup
    public let reps: Int               // 20 plyometric / 30 weight
    public let legExercise: LegExercise?   // set for plyometric (legs) phases
}

/// Plans the ordered exercises for a Shape session (Legs rule, alternation,
/// injury exclusion). Pure; seeded (Q4/Q5/Q6).
public enum ShapeExercisePlanner {

    public static func plan(choice: ShapeSessionChoice, type: WorkoutType,
                            legUnlock: LevelUpUnlock?, seed: UInt64) -> [PlannedExercise] {
        let roles = ShapeAlternation.roles(for: type)
        // Pre-draw a leg sequence long enough for all possible leg phases.
        let eligibleLegs = ExerciseSelector.eligible(bank: LegExerciseBank.all, unlock: legUnlock)
        let legSeq = ExerciseSelector.sequence(eligible: eligibleLegs, count: roles.count, seed: seed)
        var legIdx = 0
        // Per-muscle weight sequences (seeded, no-repeat), lazily built.
        var weightSeqs: [MuscleGroup: [WeightExercise]] = [:]
        var weightIdx: [MuscleGroup: Int] = [:]

        func nextWeight(_ muscle: MuscleGroup) -> WeightExercise? {
            if weightSeqs[muscle] == nil {
                weightSeqs[muscle] = seededSequence(WeightExerciseBank.exercises(for: muscle),
                                                    count: roles.count, seed: seed &+ UInt64(muscle.hashValue & 0xffff))
                weightIdx[muscle] = 0
            }
            guard let seq = weightSeqs[muscle], !seq.isEmpty else { return nil }
            let i = weightIdx[muscle] ?? 0
            weightIdx[muscle] = i + 1
            return seq[i % seq.count]
        }

        func nextLeg() -> LegExercise? {
            guard !legSeq.isEmpty else { return nil }
            defer { legIdx += 1 }
            return legSeq[legIdx % legSeq.count]
        }

        return roles.map { role in
            let muscle: MuscleGroup = (choice.option == .plyometric)
                ? .legs
                : (role == .priority ? (choice.priority ?? .legs) : (choice.secondary ?? .legs))
            if muscle == .legs {
                let leg = nextLeg()
                return PlannedExercise(name: leg?.name ?? "Plyometric legs", muscle: .legs,
                                       reps: 20, legExercise: leg)
            } else {
                let w = nextWeight(muscle)
                return PlannedExercise(name: w?.name ?? muscle.displayName, muscle: muscle,
                                       reps: 30, legExercise: nil)
            }
        }
    }

    /// Generic seeded Fisher–Yates draw without replacement (reshuffle on exhaustion).
    private static func seededSequence<T>(_ items: [T], count: Int, seed: UInt64) -> [T] {
        guard count > 0, !items.isEmpty else { return [] }
        var rng = SeededGenerator(seed: seed)
        var result: [T] = []
        var pool: [T] = []
        while result.count < count {
            if pool.isEmpty {
                pool = items
                for i in stride(from: pool.count - 1, to: 0, by: -1) {
                    let j = Int(rng.next() % UInt64(i + 1)); pool.swapAt(i, j)
                }
            }
            result.append(pool.removeFirst())
        }
        return result
    }
}
