import Foundation

/// Shape Option B weight-training banks (§G) — 6 standing free-weight exercises per
/// muscle group (chest/back/shoulders/arms/abs). Legs has none (Legs rule → plyometric).
/// Transcribed from §G; flagged for collaborator confirmation (exercise↔muscle + load guidance).
public enum WeightExerciseBank {

    public static func exercises(for muscle: MuscleGroup) -> [WeightExercise] {
        (all[muscle] ?? []).enumerated().map { i, name in
            WeightExercise(id: "\(muscle.rawValue)_\(i)", name: name, muscle: muscle)
        }
    }

    private static let all: [MuscleGroup: [String]] = [
        .chest: ["Standing dumbbell chest press", "Standing dumbbell fly", "Standing chest squeeze press",
                 "Standing incline press", "Standing single-arm cross-body press", "Standing dumbbell pullover"],
        .back: ["Standing bent-over row", "Standing single-arm row", "Standing reverse fly",
                "Standing dumbbell shrugs", "Standing W raises", "Standing band/dumbbell pull-apart"],
        .shoulders: ["Standing dumbbell shoulder press", "Standing lateral raise", "Standing front raise",
                     "Standing Arnold press", "Standing upright row", "Standing alternating shoulder press"],
        .arms: ["Standing bicep curl", "Standing hammer curl", "Standing overhead triceps extension",
                "Standing triceps kickback", "Standing concentration-style curl", "Standing dumbbell punch/press-out"],
        .abs: ["Standing dumbbell side bend", "Standing woodchopper", "Standing bicycle crunch",
               "Standing overhead reach and twist", "Standing high knee with twist", "Standing weighted torso twist"],
        // .legs intentionally absent — uses the plyometric LegExerciseBank (Legs rule).
    ]
}
