import Foundation

/// Mutable per-session state for CoachingEngine v2. Carries the seeded RNG,
/// phrase history (no-3×-repeat), off-zone run length (escalation), and
/// in-zone progress (once-per-block confirmation). Not persisted.
public struct CoachingSessionState: Sendable {
    public private(set) var rng: SeededGenerator
    /// Last up to two phrases chosen per category (BR-2-9).
    private var recent: [PhraseCategory: [String]] = [:]

    public var currentPhaseIndex: Int?
    /// Consecutive off-zone seconds in the current phase (escalation, BR-2-7).
    public var offRunSec: Int = 0
    /// Cumulative in-range seconds in the current phase (in-zone eligibility).
    public var inZoneCumSec: Int = 0
    public var inZonePraisedPhases: Set<Int> = []
    public var endAnnouncedPhases: Set<Int> = []
    public var lastEscalationSec: Int?

    public init(seed: UInt64) { self.rng = SeededGenerator(seed: seed) }

    /// Reset per-phase counters when entering a new phase.
    public mutating func enterPhase(_ index: Int) {
        guard currentPhaseIndex != index else { return }
        currentPhaseIndex = index
        offRunSec = 0
        inZoneCumSec = 0
    }

    /// Select a phrase for a category, honoring the no-3×-repeat rule.
    public mutating func nextPhrase(_ category: PhraseCategory) -> String {
        let last = recent[category] ?? []
        let phrase = PhrasePool.select(category, recent: last, using: &rng)
        var updated = last
        updated.append(phrase)
        if updated.count > 2 { updated.removeFirst(updated.count - 2) }
        recent[category] = updated
        return phrase
    }
}
