import Foundation

/// Pure weight/length unit conversions (BR-2). Canonical storage is metric.
public enum UnitConverter {
    private static let kgPerLb = 0.45359237
    private static let cmPerInch = 2.54

    public static func lbsToKg(_ lbs: Double) -> Double { lbs * kgPerLb }
    public static func kgToLbs(_ kg: Double) -> Double { kg / kgPerLb }
    public static func inchesToCm(_ inches: Double) -> Double { inches * cmPerInch }
    public static func cmToInches(_ cm: Double) -> Double { cm / cmPerInch }
}

/// Body-mass index (BR-3).
public enum BMI {
    /// weight(kg) / height(m)². Returns nil for non-positive height.
    public static func calculate(weightKg: Double, heightCm: Double) -> Double? {
        guard heightCm > 0 else { return nil }
        let m = heightCm / 100.0
        return weightKg / (m * m)
    }
}
