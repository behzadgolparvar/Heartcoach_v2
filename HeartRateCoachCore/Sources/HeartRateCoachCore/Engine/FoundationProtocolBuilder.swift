import Foundation

/// Builds the deterministic Foundation timeline for a workout type (spec §Phase 1).
/// Pure — no I/O. Appends the buffer (Continuous only), the user-paced transition
/// gate, and the 6-step cooldown (BR-2-2/3/17/18).
public enum FoundationProtocolBuilder {

    public static func build(type: WorkoutType) -> FoundationProtocol {
        switch type {
        case .continuous: return FoundationProtocol(type: .continuous, phases: continuousPhases())
        case .hiit:       return FoundationProtocol(type: .hiit, phases: hiitPhases())
        case .fartlek:    return FoundationProtocol(type: .continuous, phases: continuousPhases()) // removed in v5; defensive fallback
        }
    }

    // MARK: - Continuous (7 × 5:00, §Phase 1 table)

    private static func continuousPhases() -> [FoundationPhase] {
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
            phases.append(FoundationPhase(
                index: idx, kind: i == 0 ? .warmup : .block,
                durationSec: 300, target: block.0, label: block.1))
            idx += 1
        }
        // 30s slow-walk + breathing buffer (Continuous only).
        phases.append(FoundationPhase(index: idx, kind: .buffer, durationSec: 30,
                                      target: nil, label: "Cool-down walk")); idx += 1
        phases.append(contentsOf: tail(startIndex: &idx))
        return phases
    }

    // MARK: - HIIT (5:00 warm-up + 15 × (1:00 work / 1:00 rest), 6 intensity blocks)

    private static func hiitPhases() -> [FoundationPhase] {
        var phases: [FoundationPhase] = []
        var idx = 0
        // Warm-up matches round 1–2 intensity.
        phases.append(FoundationPhase(index: idx, kind: .warmup, durationSec: 300,
            target: TargetRange(lowPctHRR: 0.65, highPctHRR: 0.75), label: "Warm-up")); idx += 1
        for round in 1...15 {
            phases.append(FoundationPhase(index: idx, kind: .work, durationSec: 60,
                target: workTarget(round: round), label: "Round \(round)")); idx += 1
            phases.append(FoundationPhase(index: idx, kind: .rest, durationSec: 60,
                target: nil, label: "Walk — recover")); idx += 1
        }
        phases.append(contentsOf: tail(startIndex: &idx)) // no buffer before transition for HIIT
        return phases
    }

    /// Work %HRR by round group — the "6 true blocks" (spec §Phase 1 HIIT table).
    private static func workTarget(round: Int) -> TargetRange {
        switch round {
        case 1...2:   return TargetRange(lowPctHRR: 0.65, highPctHRR: 0.75)
        case 3...5:   return TargetRange(lowPctHRR: 0.70, highPctHRR: 0.80)
        case 6...8:   return TargetRange(lowPctHRR: 0.75, highPctHRR: 0.85)
        case 9...11:  return TargetRange(lowPctHRR: 0.80, highPctHRR: 0.90)
        case 12...13: return TargetRange(lowPctHRR: 0.75, highPctHRR: 0.85)
        default:      return TargetRange(lowPctHRR: 0.80, highPctHRR: 0.90) // 14–15 finish
        }
    }

    // MARK: - Shared tail: transition gate + cooldown

    private static func tail(startIndex idx: inout Int) -> [FoundationPhase] {
        var phases: [FoundationPhase] = []
        // User-paced "ready to stretch" gate (Q8): nil duration, waits for the tap.
        phases.append(FoundationPhase(index: idx, kind: .transition, durationSec: nil,
                                      target: nil, label: "Ready to stretch?")); idx += 1
        for step in CooldownStep.allCases {
            phases.append(FoundationPhase(index: idx, kind: .cooldown, durationSec: step.durationSec,
                                          target: nil, label: step.label)); idx += 1
        }
        return phases
    }
}
