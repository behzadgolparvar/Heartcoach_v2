import Foundation

/// Segment type of a Foundation session phase. Drives both coaching and scoring:
/// only `.warmup/.block/.work` are HR-coached and counted in the score denominator
/// (BR-2-12); `.rest/.buffer/.transition/.cooldown` are recorded but not scored.
public enum PhaseKind: String, Codable, Sendable, CaseIterable {
    case warmup, block, work, rest, buffer, transition, cooldown

    /// True when this phase counts toward the score (numerator + denominator).
    public var isScored: Bool {
        switch self {
        case .warmup, .block, .work: return true
        case .rest, .buffer, .transition, .cooldown: return false
        }
    }
}

/// A per-block heart-rate target expressed as a %HRR band (spec §Phase 1),
/// convertible to a bpm window for a given user via Karvonen (BR-2-1).
public struct TargetRange: Sendable, Equatable {
    public let lowPctHRR: Double
    public let highPctHRR: Double

    public init(lowPctHRR: Double, highPctHRR: Double) {
        self.lowPctHRR = lowPctHRR
        self.highPctHRR = highPctHRR
    }

    /// bpm = restingHR + pct · (maxHR − restingHR), rounded. BR-2-1.
    public func bpmRange(restingHR: Int, maxHR: Int) -> ClosedRange<Int> {
        let hrr = Double(maxHR - restingHR)
        let low = Int((Double(restingHR) + lowPctHRR * hrr).rounded())
        let high = Int((Double(restingHR) + highPctHRR * hrr).rounded())
        return min(low, high)...max(low, high)
    }
}

/// One timed segment of a Foundation session.
public struct FoundationPhase: Sendable, Equatable {
    public let index: Int
    public let kind: PhaseKind
    /// nil only for the user-paced `transition` gate (Q8).
    public let durationSec: Int?
    /// Present for `warmup/block/work`; nil otherwise.
    public let target: TargetRange?
    public let label: String

    public init(index: Int, kind: PhaseKind, durationSec: Int?,
                target: TargetRange?, label: String) {
        self.index = index
        self.kind = kind
        self.durationSec = durationSec
        self.target = target
        self.label = label
    }

    /// HR-coached only when the phase is scored and has a target.
    public var isHRCoached: Bool { kind.isScored && target != nil }
}

/// The full deterministic timeline for a Foundation session.
public struct FoundationProtocol: Sendable, Equatable {
    public let type: WorkoutType
    public let phases: [FoundationPhase]

    public init(type: WorkoutType, phases: [FoundationPhase]) {
        self.type = type
        self.phases = phases
    }

    /// Total of scored-phase durations (the 35:00 "training time").
    public var trainingDurationSec: Int {
        phases.filter { $0.kind.isScored }.compactMap { $0.durationSec }.reduce(0, +)
    }
}
