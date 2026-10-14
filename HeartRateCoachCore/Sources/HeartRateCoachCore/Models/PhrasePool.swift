import Foundation

/// Phrase pools per situation, with no-same-phrase-3×-in-a-row rotation (BR-2-9).
/// Phrase wording is intentionally compact here; the full spec phrase lists
/// (v3 spec §4) can be dropped in later without changing the selection logic.
public enum PhrasePool {

    public static let variants: [PhraseCategory: [String]] = [
        .offMinorLow: [
            "A touch under — pick it up slightly.",
            "Just below target — a little more effort.",
            "Ease the pace up a bit.",
            "Nudge it up — almost there.",
            "Small lift in effort now.",
        ],
        .offMinorHigh: [
            "A touch high — ease back slightly.",
            "Just above target — soften the pace.",
            "Back off a hair.",
            "Bring it down a notch.",
            "Slightly too hard — relax a little.",
        ],
        .offMajorLow: [
            "Well below target — push harder.",
            "Pick up the pace now.",
            "More effort — get that heart rate up.",
            "You're coasting — step it up.",
            "Dig in, lift the intensity.",
        ],
        .offMajorHigh: [
            "Too high — slow it down now.",
            "Ease off, bring your heart rate down.",
            "Back right off the pace.",
            "Slow down and breathe.",
            "That's too hard — recover the pace.",
        ],
        .inZone: [
            "Perfect — right where you want to be.",
            "Dialed in. Hold it there.",
            "Great pacing — stay with it.",
            "Spot on. Keep it steady.",
        ],
        .escalationLow: [
            "You've been under for a while — commit to the effort.",
            "Let's close the gap — lift it and hold.",
            "Still coasting — real effort now.",
        ],
        .escalationHigh: [
            "You've been too high for a while — slow down now.",
            "Bring it down and keep it there.",
            "Still over — ease the pace and settle.",
        ],
        .endOfPhase: [
            "Almost through this block.",
            "Ten seconds — finish strong.",
            "Nearly there — hold it.",
        ],
        .blockStart: [
            "New block — settle into the target.",
            "Here we go — find your pace.",
            "Next block starting now.",
        ],
        .roundsLeft: [
            "Keep going — you've got this.",
            "Strong work — stay with it.",
            "Hold the effort.",
        ],
        .restInstruction: [
            "Take a walk, normal pace.",
            "Walk it out and breathe.",
            "Easy walk — recover.",
        ],
        .closingExcellent: ["Excellent work — you nailed your targets today."],
        .closingGreat: ["Great session — you held your zones well."],
        .closingGood: ["Good work today — solid effort."],
        .closingFair: ["Decent session — a bit more time in zone next time."],
        .closingNeedsWork: ["Tough one today — let's aim for more time in zone next session."],
    ]

    /// Picks a phrase for `category`, avoiding the last two choices for that
    /// category (no 3× in a row), using the session's seeded RNG.
    public static func select(_ category: PhraseCategory,
                              recent: [String],
                              using rng: inout SeededGenerator) -> String {
        let pool = variants[category] ?? ["…"]
        let candidates = pool.filter { !recent.contains($0) }
        let choices = candidates.isEmpty ? pool : candidates
        let i = Int(rng.next() % UInt64(choices.count))
        return choices[i]
    }
}
