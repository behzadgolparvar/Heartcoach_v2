import Foundation

/// Priority layers for CoachingEngine v2 (spec §D). Exactly one cue is emitted
/// per tick, chosen by the highest-priority layer that fires (BR-2-5).
/// `safety` is owned by the session driver (reuses the v1 emergency path); it is
/// listed here so the ordering is explicit.
public enum CoachingPriority: Int, Sendable, Comparable {
    case transition = 0   // block/round start, "N left"
    case inZone = 1
    case offZone = 2
    case escalation = 3
    case endOfPhase = 4
    case safety = 5       // driver-owned

    public static func < (l: CoachingPriority, r: CoachingPriority) -> Bool { l.rawValue < r.rawValue }
}

/// The situation a phrase pool addresses.
public enum PhraseCategory: String, Sendable, CaseIterable {
    case offMinorLow, offMinorHigh, offMajorLow, offMajorHigh
    case inZone
    case escalationLow, escalationHigh
    case endOfPhase
    case blockStart, roundsLeft
    case restInstruction
    case closingExcellent, closingGreat, closingGood, closingFair, closingNeedsWork
}

/// A single coaching output for one tick.
public struct CoachingCue: Sendable, Equatable {
    public let text: String
    public let category: PhraseCategory
    public let priority: CoachingPriority
    /// Session time (seconds) the cue fires — recorded as `phrase_time` in `hr_stream`.
    public let atSec: Int
    public let haptic: HapticPattern?

    public init(text: String, category: PhraseCategory, priority: CoachingPriority,
                atSec: Int, haptic: HapticPattern? = nil) {
        self.text = text
        self.category = category
        self.priority = priority
        self.atSec = atSec
        self.haptic = haptic
    }
}

/// Deterministic, seedable RNG (SplitMix64) so phrase selection is reproducible
/// in tests while still varying across sessions (BR-2-9, Q5).
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { self.state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
