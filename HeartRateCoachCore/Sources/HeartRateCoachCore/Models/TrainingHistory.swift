import Foundation

/// Q1 of the v5 experience classification (spec §A) — the *authoritative* input.
/// Training-history duration maps to a fitness tier (BR-1b-1). Shown with an
/// honesty-framing prompt in the UI.
public enum TrainingHistory: String, Codable, Sendable, CaseIterable {
    /// Never trained consistently → Beginner.
    case neverTrained = "never_trained"
    /// Trained before but stopped 1+ year ago → Beginner.
    case stoppedOverYear = "stopped_over_year"
    /// Returning after a break under a year, or <1 yr consistent → Intermediate.
    case recentReturnOrUnderYear = "recent_return_or_under_year"
    /// 1+ years consistent → Advanced.
    case overYearConsistent = "over_year_consistent"

    /// BR-1b-1 — authoritative history → tier mapping.
    public var mappedTier: FitnessExperience {
        switch self {
        case .neverTrained, .stoppedOverYear: return .beginner
        case .recentReturnOrUnderYear: return .intermediate
        case .overYearConsistent: return .advanced
        }
    }

    public var displayName: String {
        switch self {
        case .neverTrained: return "I've never trained consistently"
        case .stoppedOverYear: return "I trained before but stopped 1+ year ago"
        case .recentReturnOrUnderYear: return "I'm returning after a break under a year, or have trained under a year consistently"
        case .overYearConsistent: return "I've trained consistently for 1+ years"
        }
    }
}
