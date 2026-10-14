import Foundation

/// Builds the Shape timelines (§3.1 Continuous, §3.2 HIIT) from planned exercises.
/// Pure. Reuses the `FoundationProtocol` model + `.exercise` phase; appends
/// buffer/transition/cooldown.
public enum ShapeProtocolBuilder {

    /// Exercise phases per session: Continuous = 6; HIIT = 11.
    public static func exerciseCount(for type: WorkoutType) -> Int {
        type == .hiit ? 11 : 6
    }

    public static func build(type: WorkoutType, planned: [PlannedExercise]) -> FoundationProtocol {
        switch type {
        case .hiit: return FoundationProtocol(type: .hiit, phases: hiit(planned))
        default:    return FoundationProtocol(type: .continuous, phases: continuous(planned))
        }
    }

    private static func exercisePhase(_ idx: Int, _ p: PlannedExercise?) -> FoundationPhase {
        FoundationPhase(index: idx, kind: .exercise, durationSec: 60, target: nil,
                        exercise: p?.legExercise, exerciseReps: p?.reps ?? 30,
                        muscle: p?.muscle, label: p?.name ?? "Exercise")
    }

    // MARK: - Continuous (§3.1)

    private static func continuous(_ planned: [PlannedExercise]) -> [FoundationPhase] {
        // (kind, runSec, %HRR, label). Block 1 = 6:00 (run 230); Blocks 2–6 = 5:00 (run 170); Block 7 pure run 240.
        let blocks: [(PhaseKind, Int, TargetRange, String)] = [
            (.warmup, 230, TargetRange(lowPctHRR: 0.50, highPctHRR: 0.60), "Block 1 — Warm-up"),
            (.block, 170, TargetRange(lowPctHRR: 0.60, highPctHRR: 0.70), "Block 2"),
            (.block, 170, TargetRange(lowPctHRR: 0.65, highPctHRR: 0.75), "Block 3"),
            (.block, 170, TargetRange(lowPctHRR: 0.70, highPctHRR: 0.80), "Block 4"),
            (.block, 170, TargetRange(lowPctHRR: 0.75, highPctHRR: 0.85), "Block 5 — Peak"),
            (.block, 170, TargetRange(lowPctHRR: 0.70, highPctHRR: 0.80), "Block 6 — Ease back"),
        ]
        var phases: [FoundationPhase] = []
        var idx = 0
        for (i, b) in blocks.enumerated() {
            phases.append(FoundationPhase(index: idx, kind: b.0, durationSec: b.1, target: b.2, label: b.3)); idx += 1
            phases.append(exercisePhase(idx, planned[safe: i])); idx += 1
            phases.append(FoundationPhase(index: idx, kind: .rest, durationSec: 70, target: nil, label: "Walk")); idx += 1
        }
        // Block 7 — pure run.
        phases.append(FoundationPhase(index: idx, kind: .block, durationSec: 240,
            target: TargetRange(lowPctHRR: 0.75, highPctHRR: 0.85), label: "Block 7 — Finish")); idx += 1
        phases.append(contentsOf: tail(startIndex: &idx, buffer: true))
        return phases
    }

    // MARK: - HIIT (§3.2)

    private static func hiit(_ planned: [PlannedExercise]) -> [FoundationPhase] {
        let runHR: [TargetRange] = [
            .init(lowPctHRR: 0.65, highPctHRR: 0.75), .init(lowPctHRR: 0.70, highPctHRR: 0.80),
            .init(lowPctHRR: 0.70, highPctHRR: 0.80), .init(lowPctHRR: 0.75, highPctHRR: 0.85),
            .init(lowPctHRR: 0.75, highPctHRR: 0.85), .init(lowPctHRR: 0.80, highPctHRR: 0.90),
            .init(lowPctHRR: 0.80, highPctHRR: 0.90), .init(lowPctHRR: 0.75, highPctHRR: 0.85),
            .init(lowPctHRR: 0.80, highPctHRR: 0.90), .init(lowPctHRR: 0.80, highPctHRR: 0.90),
        ]
        var phases: [FoundationPhase] = []
        var idx = 0
        phases.append(FoundationPhase(index: idx, kind: .warmup, durationSec: 180,
            target: TargetRange(lowPctHRR: 0.50, highPctHRR: 0.60), label: "Warm-up")); idx += 1
        // Exercise Phase 0 (before the rounds).
        phases.append(exercisePhase(idx, planned[safe: 0])); idx += 1
        phases.append(FoundationPhase(index: idx, kind: .rest, durationSec: 70, target: nil, label: "Walk")); idx += 1
        // 10 rounds: 0:50 run → exercise phase (phases 1…10).
        for r in 0..<10 {
            phases.append(FoundationPhase(index: idx, kind: .work, durationSec: 50,
                target: runHR[r], label: "Round \(r + 1)")); idx += 1
            phases.append(exercisePhase(idx, planned[safe: r + 1])); idx += 1
            phases.append(FoundationPhase(index: idx, kind: .rest, durationSec: 70, target: nil, label: "Walk")); idx += 1
        }
        phases.append(contentsOf: tail(startIndex: &idx, buffer: false))
        return phases
    }

    // MARK: - Shared tail

    private static func tail(startIndex idx: inout Int, buffer: Bool) -> [FoundationPhase] {
        var phases: [FoundationPhase] = []
        if buffer {
            phases.append(FoundationPhase(index: idx, kind: .buffer, durationSec: 30, target: nil, label: "Cool-down walk")); idx += 1
        }
        phases.append(FoundationPhase(index: idx, kind: .transition, durationSec: nil, target: nil, label: "Ready to stretch?")); idx += 1
        for step in CooldownStep.allCases {
            phases.append(FoundationPhase(index: idx, kind: .cooldown, durationSec: step.durationSec, target: nil, label: step.label)); idx += 1
        }
        return phases
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
