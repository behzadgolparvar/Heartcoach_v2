import Foundation

/// Relapse / re-entry penalty band from the gap since the last counted session (§C).
public enum RelapseBand: String, Sendable, Equatable {
    case none
    case pushBack3
    case pushBack5
    case pushBack8
    case resetToStart

    /// BR-3-7 — gap in whole days → band. Week/month labels fixed to day cut-offs
    /// for determinism: ≤7 none · 8–14 −3 · 15–21 −5 · 22–30 −8 · >30 reset.
    public static func from(gapDays: Int) -> RelapseBand {
        switch gapDays {
        case ..<8:    return .none
        case 8...14:  return .pushBack3
        case 15...21: return .pushBack5
        case 22...30: return .pushBack8
        default:      return .resetToStart
        }
    }

    /// Sessions to subtract (resetToStart handled separately as "to 0").
    public var pushBack: Int {
        switch self {
        case .none: return 0
        case .pushBack3: return 3
        case .pushBack5: return 5
        case .pushBack8: return 8
        case .resetToStart: return 0
        }
    }
}

/// Result of applying relapse, for positive-framing UI (§C).
public struct RelapseOutcome: Sendable, Equatable {
    public let band: RelapseBand
    public let sessionsBefore: Int
    public let sessionsAfter: Int

    public init(band: RelapseBand, sessionsBefore: Int, sessionsAfter: Int) {
        self.band = band
        self.sessionsBefore = sessionsBefore
        self.sessionsAfter = sessionsAfter
    }
}
