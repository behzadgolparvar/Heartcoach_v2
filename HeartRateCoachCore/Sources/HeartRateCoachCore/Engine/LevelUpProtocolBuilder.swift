import Foundation

/// Builds the Level Up timelines (§2.1 Continuous, §2.2 HIIT) with leg-exercise
/// phases woven in. Pure; takes pre-selected exercises (`ExerciseSelector`).
/// Reuses the P2 `FoundationProtocol`/`FoundationPhase` model + `.exercise` kind.
public enum LevelUpProtocolBuilder {

    /// Exercises needed per session: Continuous = 6 (Blocks 1–6); HIIT = 11
    /// (post-warmup block + 10 rounds).
    public static func exerciseCount(for type: WorkoutType) -> Int {
        type == .hiit ? 11 : 6
    }

    public static func build(type: WorkoutType, exercises: [LegExercise]) -> FoundationProtocol {
        switch type {
        case .hiit: return FoundationProtocol(type: .hiit, phases: hiit(exercises))
        default:    return FoundationProtocol(type: .continuous, phases: continuous(exercises))
        }
    }

    // MARK: - Continuous (§2.1)

    private static func continuous(_ ex: [LegExercise]) -> [FoundationPhase] {
        let blocks: [(TargetRange, String)] = [
            (TargetRange(lowPctHRR: 0.50, highPctHRR: 0.60), "Block 1 — Warm-up"),
            (TargetRange(lowPctHRR: 0.60, highPctHRR: 0.70), "Block 2"),
            (TargetRange(lowPctHRR: 0.65, highPctHRR: 0.75), "Block 3"),
            (TargetRange(lowPctHRR: 0.70, highPctHRR: 0.80), "Block 4"),
            (TargetRange(lowPctHRR: 0.75, highPctHRR: 0.85), "Block 5 — Peak"),
            (TargetRange(lowPctHRR: 0.70, highPctHRR: 0.80), "Block 6 — Ease back"),
            (TargetRange(lowPctHRR: 0.75, highPctHRR: 0.85), "Block 7 — Finish"),
        ]
        var phases: [FoundationPhase] = []
        var idx = 0
        for (i, block) in blocks.enumerated() {
            if i < 6 {
                // Run 0:00–3:50, then exercise, then walk to 5:00.
                phases.append(FoundationPhase(index: idx, kind: i == 0 ? .warmup : .block,
                    durationSec: 230, target: block.0, label: block.1)); idx += 1
                let e = ex[i % max(1, ex.count)]
                phases.append(FoundationPhase(index: idx, kind: .exercise, durationSec: e.mode.durationSec,
                    target: nil, exercise: e, exerciseReps: e.mode.reps, label: e.name)); idx += 1
                let walk = 300 - 230 - e.mode.durationSec
                phases.append(FoundationPhase(index: idx, kind: .rest, durationSec: walk,
                    target: nil, label: "Walk")); idx += 1
            } else {
                // Block 7: pure run, no exercise.
                phases.append(FoundationPhase(index: idx, kind: .block, durationSec: 300,
                    target: block.0, label: block.1)); idx += 1
            }
        }
        phases.append(contentsOf: tail(startIndex: &idx, buffer: true))
        return phases
    }

    // MARK: - HIIT (§2.2)

    private static func hiit(_ ex: [LegExercise]) -> [FoundationPhase] {
        let roundHR: [TargetRange] = [
            .init(lowPctHRR: 0.65, highPctHRR: 0.75), .init(lowPctHRR: 0.70, highPctHRR: 0.80),
            .init(lowPctHRR: 0.70, highPctHRR: 0.80), .init(lowPctHRR: 0.75, highPctHRR: 0.85),
            .init(lowPctHRR: 0.75, highPctHRR: 0.85), .init(lowPctHRR: 0.80, highPctHRR: 0.90),
            .init(lowPctHRR: 0.80, highPctHRR: 0.90), .init(lowPctHRR: 0.75, highPctHRR: 0.85),
            .init(lowPctHRR: 0.80, highPctHRR: 0.90), .init(lowPctHRR: 0.80, highPctHRR: 0.90),
        ]
        var phases: [FoundationPhase] = []
        var idx = 0
        // Warm-up 0:00–3:00.
        phases.append(FoundationPhase(index: idx, kind: .warmup, durationSec: 180,
            target: TargetRange(lowPctHRR: 0.50, highPctHRR: 0.60), label: "Warm-up")); idx += 1
        // Post-warmup exercise block 3:00–5:00 (120s).
        let firstEx = ex.isEmpty ? nil : ex[0]
        phases.append(FoundationPhase(index: idx, kind: .exercise, durationSec: 120,
            target: nil, exercise: firstEx, exerciseReps: 20, label: firstEx?.name ?? "Exercise")); idx += 1
        // 10 rounds × 3:00: 1:00 run → exercise (20 reps, 60s) → walk 60s.
        for r in 0..<10 {
            phases.append(FoundationPhase(index: idx, kind: .work, durationSec: 60,
                target: roundHR[r], label: "Round \(r + 1)")); idx += 1
            let e = ex.isEmpty ? nil : ex[(r + 1) % ex.count]
            phases.append(FoundationPhase(index: idx, kind: .exercise, durationSec: 60,
                target: nil, exercise: e, exerciseReps: 20, label: e?.name ?? "Exercise")); idx += 1
            phases.append(FoundationPhase(index: idx, kind: .rest, durationSec: 60,
                target: nil, label: "Walk — recover")); idx += 1
        }
        phases.append(contentsOf: tail(startIndex: &idx, buffer: false))
        return phases
    }

    // MARK: - Shared tail (buffer? + transition gate + cooldown)

    private static func tail(startIndex idx: inout Int, buffer: Bool) -> [FoundationPhase] {
        var phases: [FoundationPhase] = []
        if buffer {
            phases.append(FoundationPhase(index: idx, kind: .buffer, durationSec: 30,
                target: nil, label: "Cool-down walk")); idx += 1
        }
        phases.append(FoundationPhase(index: idx, kind: .transition, durationSec: nil,
            target: nil, label: "Ready to stretch?")); idx += 1
        for step in CooldownStep.allCases {
            phases.append(FoundationPhase(index: idx, kind: .cooldown, durationSec: step.durationSec,
                target: nil, label: step.label)); idx += 1
        }
        return phases
    }
}
