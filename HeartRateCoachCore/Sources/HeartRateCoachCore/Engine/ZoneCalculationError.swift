import Foundation

/// Thrown by ZoneCalculator when input values are physiologically impossible.
public enum ZoneCalculationError: Error, Sendable {
    /// Age is outside the accepted range of 15–100.
    case invalidAge(value: Int)
    /// Resting HR is zero, negative, or equal to/greater than HRmax (220 - age).
    case invalidRestingHR(value: Int)
}

/// Returned alongside valid zones when resting HR is outside the typical 40–100 bpm range.
/// Does not prevent zone calculation — the UI surfaces this as a warning prompt.
public enum RHRWarning: Sendable {
    /// Resting HR is below 40 bpm.
    case belowTypicalRange
    /// Resting HR is above 100 bpm.
    case aboveTypicalRange
}
