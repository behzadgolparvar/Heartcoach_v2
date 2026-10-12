import Foundation

/// The Level Up leg-exercise bank (§G) — 8 standing plyometric moves.
/// Mode + joint tags are defaults FLAGGED for collaborator confirmation (safety).
/// Spec line 59 says "20+"; §G lists 8 — expansion is data-only (append here).
public enum LegExerciseBank {
    public static let all: [LegExercise] = [
        LegExercise(id: "squat_jumps", name: "Squat jumps", mode: .bilateral, impactedJoints: [.knee, .ankle]),
        LegExercise(id: "jumping_lunges", name: "Jumping lunges", mode: .unilateral, impactedJoints: [.knee, .hip]),
        LegExercise(id: "lateral_bounds", name: "Lateral bounds", mode: .bilateral, impactedJoints: [.knee, .ankle, .hip]),
        LegExercise(id: "step_up_jumps", name: "Step-up jumps", mode: .unilateral, impactedJoints: [.knee, .hip]),
        LegExercise(id: "skater_jumps", name: "Skater jumps", mode: .unilateral, impactedJoints: [.knee, .ankle]),
        LegExercise(id: "jump_rope", name: "Jump rope", mode: .bilateral, impactedJoints: [.ankle]),
        LegExercise(id: "broad_jumps", name: "Broad jumps", mode: .bilateral, impactedJoints: [.knee, .ankle]),
        LegExercise(id: "split_squat_jumps", name: "Split squat jumps", mode: .unilateral, impactedJoints: [.knee, .hip]),
    ]
}
