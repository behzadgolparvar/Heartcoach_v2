import Foundation

/// Post-session score tier (spec §D/FR-6). Cutoffs per Q10=A (even bands).
public enum ScoreTier: String, Codable, Sendable, CaseIterable {
    case excellent, great, good, fair, needsWork

    /// BR-2-14 — boundaries inclusive at the lower number.
    public static func from(percent: Double) -> ScoreTier {
        switch percent {
        case 90...:      return .excellent
        case 75..<90:    return .great
        case 60..<75:    return .good
        case 40..<60:    return .fair
        default:         return .needsWork
        }
    }

    public var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .great: return "Great"
        case .good: return "Good"
        case .fair: return "Fair"
        case .needsWork: return "Needs Work"
        }
    }

    /// Tier-matched closing phrase pool (BR-2-15).
    public var closingCategory: PhraseCategory {
        switch self {
        case .excellent: return .closingExcellent
        case .great: return .closingGreat
        case .good: return .closingGood
        case .fair: return .closingFair
        case .needsWork: return .closingNeedsWork
        }
    }
}

/// The computed result of a session.
public struct SessionScore: Codable, Sendable, Equatable {
    /// % of scored training seconds spent inside the per-block target (BR-2-13).
    public let percentInTarget: Double
    public let tier: ScoreTier
    /// Seconds spent in each HR zone (1–5) during scored phases — visual summary.
    public let timeInZoneSec: [Int: Int]

    public init(percentInTarget: Double, tier: ScoreTier, timeInZoneSec: [Int: Int]) {
        self.percentInTarget = percentInTarget
        self.tier = tier
        self.timeInZoneSec = timeInZoneSec
    }
}
