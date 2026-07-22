import Foundation

/// Computes personalised heart rate zones using the Karvonen formula.
///
/// All methods are static and stateless — no shared mutable state.
/// Zone boundaries are ceiled to the nearest integer (BR-03).
/// At exact boundary values, the lower zone wins (BR-05).
public struct ZoneCalculator {

    // MARK: - Public API

    /// Returns the estimated maximum heart rate for the given age.
    /// Formula: HRmax = 220 - age
    public static func maxHR(for age: Int) -> Int {
        return 220 - age
    }

    /// Computes the five personalised HR zones using the Karvonen formula.
    ///
    /// - Parameters:
    ///   - age: User's age in years. Must be in range 15–100.
    ///   - restingHR: Resting heart rate in bpm. Must be > 0 and < HRmax.
    /// - Returns: Computed `HRZones` and an optional `RHRWarning` if restingHR is
    ///   outside the typical 40–100 range (warning does not block zone calculation).
    /// - Throws: `ZoneCalculationError.invalidAge` if age is outside 15–100.
    ///           `ZoneCalculationError.invalidRestingHR` if restingHR is ≤ 0 or ≥ HRmax.
    public static func calculate(
        age: Int,
        restingHR: Int
    ) throws -> (zones: HRZones, warning: RHRWarning?) {
        guard age >= 15 && age <= 100 else {
            throw ZoneCalculationError.invalidAge(value: age)
        }

        let hrMax = maxHR(for: age)

        guard restingHR > 0 && restingHR < hrMax else {
            throw ZoneCalculationError.invalidRestingHR(value: restingHR)
        }

        let warning: RHRWarning?
        if restingHR < 40 {
            warning = .belowTypicalRange
        } else if restingHR > 100 {
            warning = .aboveTypicalRange
        } else {
            warning = nil
        }

        let zones = buildZones(hrMax: hrMax, restingHR: restingHR)
        return (zones: zones, warning: warning)
    }

    /// Classifies a raw HR reading into a zone number.
    ///
    /// - Returns:
    ///   - 0: HR is below Zone 1 minimum
    ///   - 1–5: HR is within the corresponding zone (lower zone wins at exact boundary)
    ///   - 6: HR exceeds HRmax — safety territory
    public static func zone(for hr: Int, in zones: HRZones) -> Int {
        if hr < zones.zone1.min  { return 0 }
        if hr <= zones.zone1.max { return 1 }
        if hr <= zones.zone2.max { return 2 }
        if hr <= zones.zone3.max { return 3 }
        if hr <= zones.zone4.max { return 4 }
        if hr <= zones.zone5.max { return 5 }
        return 6
    }

    // MARK: - Private

    private static func buildZones(hrMax: Int, restingHR: Int) -> HRZones {
        let hrr = Double(hrMax - restingHR)
        let rhr = Double(restingHR)

        // Ceiling-round each boundary (BR-03). zone(n).max == zone(n+1).min (BR-04).
        func boundary(_ pct: Double) -> Int { Int(ceil(rhr + pct * hrr)) }

        let z1 = Zone(number: 1, name: "Recovery",        min: boundary(0.50), max: boundary(0.60))
        let z2 = Zone(number: 2, name: "Easy / Fat Burn", min: z1.max,          max: boundary(0.70))
        let z3 = Zone(number: 3, name: "Aerobic",         min: z2.max,          max: boundary(0.80))
        let z4 = Zone(number: 4, name: "Threshold",       min: z3.max,          max: boundary(0.90))
        let z5 = Zone(number: 5, name: "Max Effort",      min: z4.max,          max: hrMax)

        return HRZones(zone1: z1, zone2: z2, zone3: z3, zone4: z4, zone5: z5)
    }
}
