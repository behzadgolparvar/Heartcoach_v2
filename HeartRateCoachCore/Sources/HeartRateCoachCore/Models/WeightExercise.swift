import Foundation

/// A standing free-weight exercise (§G) for Shape Option B. 30 reps, ~2s/rep.
public struct WeightExercise: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let muscle: MuscleGroup

    public init(id: String, name: String, muscle: MuscleGroup) {
        self.id = id
        self.name = name
        self.muscle = muscle
    }
}
