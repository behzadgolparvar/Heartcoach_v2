import Foundation

/// Which §B progression rule-set applies to a user.
public enum ProgressionTrack: String, Sendable, Equatable {
    case beginnerFastWeightLoss
    case beginnerRoutineCardio
    case intermediate
    case advanced

    /// BR-3-1 (Q2=A): Beginner splits on goal — Fast Weight Loss wins if selected,
    /// else Routine/Cardio. Intermediate/Advanced are goal-independent.
    public static func resolve(experience: FitnessExperience, goals: Set<TrainingGoal>) -> ProgressionTrack {
        switch experience {
        case .beginner:
            return goals.contains(.fastWeightLoss) ? .beginnerFastWeightLoss : .beginnerRoutineCardio
        case .intermediate:
            return .intermediate
        case .advanced:
            return .advanced
        }
    }
}
