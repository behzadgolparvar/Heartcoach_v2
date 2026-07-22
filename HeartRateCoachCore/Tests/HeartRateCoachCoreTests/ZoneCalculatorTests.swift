import XCTest
import SwiftCheck
@testable import HeartRateCoachCore

final class ZoneCalculatorTests: XCTestCase {

    // MARK: - Example-Based Tests

    func testMaxHR() {
        XCTAssertEqual(ZoneCalculator.maxHR(for: 30), 190)
        XCTAssertEqual(ZoneCalculator.maxHR(for: 20), 200)
        XCTAssertEqual(ZoneCalculator.maxHR(for: 50), 170)
    }

    func testKarvonenFormulaKnownValues() throws {
        // age=30, rhr=60, HRmax=190, HRR=130
        // z1: ceil(60+0.5*130)=ceil(125)=125, ceil(60+0.6*130)=ceil(138)=138
        // z2: 138, ceil(60+0.7*130)=ceil(151)=151
        // z3: 151, ceil(60+0.8*130)=ceil(164)=164
        // z4: 164, ceil(60+0.9*130)=ceil(177)=177
        // z5: 177, 190
        let result = try ZoneCalculator.calculate(age: 30, restingHR: 60)
        let z = result.zones
        XCTAssertEqual(z.zone1.min, 125)
        XCTAssertEqual(z.zone1.max, 138)
        XCTAssertEqual(z.zone2.min, 138)
        XCTAssertEqual(z.zone2.max, 151)
        XCTAssertEqual(z.zone3.min, 151)
        XCTAssertEqual(z.zone3.max, 164)
        XCTAssertEqual(z.zone4.min, 164)
        XCTAssertEqual(z.zone4.max, 177)
        XCTAssertEqual(z.zone5.min, 177)
        XCTAssertEqual(z.zone5.max, 190)
        XCTAssertNil(result.warning)
    }

    func testZone5MaxEqualsHRmax() throws {
        let result = try ZoneCalculator.calculate(age: 35, restingHR: 65)
        XCTAssertEqual(result.zones.zone5.max, ZoneCalculator.maxHR(for: 35))
    }

    func testCeilingRounding() throws {
        // age=32, rhr=62, HRmax=188, HRR=126
        // z1.min = ceil(62 + 0.5*126) = ceil(62+63) = ceil(125.0) = 125
        // z1.max = ceil(62 + 0.6*126) = ceil(62+75.6) = ceil(137.6) = 138
        let result = try ZoneCalculator.calculate(age: 32, restingHR: 62)
        XCTAssertEqual(result.zones.zone1.max, 138) // ceil(137.6)
    }

    func testBoundaryLowerZoneWins() throws {
        let result = try ZoneCalculator.calculate(age: 30, restingHR: 60)
        let z = result.zones
        // HR exactly at zone1.max (138) → Zone 1 (lower zone wins)
        XCTAssertEqual(ZoneCalculator.zone(for: z.zone1.max, in: z), 1)
        // HR exactly at zone2.max (151) → Zone 2
        XCTAssertEqual(ZoneCalculator.zone(for: z.zone2.max, in: z), 2)
        // HR exactly at zone3.max (164) → Zone 3
        XCTAssertEqual(ZoneCalculator.zone(for: z.zone3.max, in: z), 3)
        // HR exactly at zone4.max (177) → Zone 4
        XCTAssertEqual(ZoneCalculator.zone(for: z.zone4.max, in: z), 4)
    }

    func testHRBelowAllZones() throws {
        let result = try ZoneCalculator.calculate(age: 30, restingHR: 60)
        let z = result.zones
        XCTAssertEqual(ZoneCalculator.zone(for: z.zone1.min - 1, in: z), 0)
    }

    func testHRAboveHRmax() throws {
        let result = try ZoneCalculator.calculate(age: 30, restingHR: 60)
        let z = result.zones
        XCTAssertEqual(ZoneCalculator.zone(for: z.zone5.max + 1, in: z), 6)
    }

    func testRHRWarningBelowRange() throws {
        let result = try ZoneCalculator.calculate(age: 30, restingHR: 35)
        XCTAssertEqual(result.warning, .belowTypicalRange)
        // Zones are still valid
        XCTAssertGreaterThan(result.zones.zone1.max, result.zones.zone1.min)
    }

    func testRHRWarningAboveRange() throws {
        let result = try ZoneCalculator.calculate(age: 30, restingHR: 110)
        XCTAssertEqual(result.warning, .aboveTypicalRange)
        XCTAssertGreaterThan(result.zones.zone1.max, result.zones.zone1.min)
    }

    func testNoWarningForTypicalRHR() throws {
        let result = try ZoneCalculator.calculate(age: 30, restingHR: 65)
        XCTAssertNil(result.warning)
    }

    func testInvalidAgeLow() {
        XCTAssertThrowsError(try ZoneCalculator.calculate(age: 10, restingHR: 60)) { error in
            guard case ZoneCalculationError.invalidAge(let v) = error else {
                return XCTFail("Expected invalidAge, got \(error)")
            }
            XCTAssertEqual(v, 10)
        }
    }

    func testInvalidAgeHigh() {
        XCTAssertThrowsError(try ZoneCalculator.calculate(age: 105, restingHR: 60)) { error in
            guard case ZoneCalculationError.invalidAge = error else {
                return XCTFail("Expected invalidAge, got \(error)")
            }
        }
    }

    func testInvalidRHRZero() {
        XCTAssertThrowsError(try ZoneCalculator.calculate(age: 30, restingHR: 0)) { error in
            guard case ZoneCalculationError.invalidRestingHR(let v) = error else {
                return XCTFail("Expected invalidRestingHR, got \(error)")
            }
            XCTAssertEqual(v, 0)
        }
    }

    // MARK: - Property-Based Tests (SwiftCheck)

    func testZoneBoundariesStrictlyIncreasing() {
        property("zone boundaries are strictly increasing for all valid profiles")
            <- forAll(validProfileGen) { profile in
                guard let result = try? ZoneCalculator.calculate(age: profile.age, restingHR: profile.restingHR) else {
                    return false
                }
                let z = result.zones
                return z.zone1.max < z.zone2.max
                    && z.zone2.max < z.zone3.max
                    && z.zone3.max < z.zone4.max
                    && z.zone4.max < z.zone5.max
            }
    }

    func testNoGapsBetweenZones() {
        property("zone(n).max == zone(n+1).min for all valid profiles")
            <- forAll(validProfileGen) { profile in
                guard let result = try? ZoneCalculator.calculate(age: profile.age, restingHR: profile.restingHR) else {
                    return false
                }
                let z = result.zones
                return z.zone1.max == z.zone2.min
                    && z.zone2.max == z.zone3.min
                    && z.zone3.max == z.zone4.min
                    && z.zone4.max == z.zone5.min
            }
    }

    func testZone5MaxEqualsHRmaxProperty() {
        property("zone5.max always equals HRmax (220 - age)")
            <- forAll(validProfileGen) { profile in
                guard let result = try? ZoneCalculator.calculate(age: profile.age, restingHR: profile.restingHR) else {
                    return false
                }
                return result.zones.zone5.max == ZoneCalculator.maxHR(for: profile.age)
            }
    }

    func testZoneClassificationConsistency() {
        property("zone() returns correct zone for HR within each zone's range")
            <- forAll(validProfileGen) { profile in
                guard let result = try? ZoneCalculator.calculate(age: profile.age, restingHR: profile.restingHR) else {
                    return false
                }
                let z = result.zones
                // Test midpoint of each zone
                let mid1 = (z.zone1.min + z.zone1.max) / 2
                let mid2 = (z.zone2.min + z.zone2.max) / 2
                let mid3 = (z.zone3.min + z.zone3.max) / 2
                let mid4 = (z.zone4.min + z.zone4.max) / 2
                let mid5 = (z.zone5.min + z.zone5.max) / 2
                return ZoneCalculator.zone(for: mid1, in: z) == 1
                    && ZoneCalculator.zone(for: mid2, in: z) == 2
                    && ZoneCalculator.zone(for: mid3, in: z) == 3
                    && ZoneCalculator.zone(for: mid4, in: z) == 4
                    && ZoneCalculator.zone(for: mid5, in: z) == 5
            }
    }

    func testBoundaryClassificationProperty() {
        property("HR at zone(n).max classifies as zone n (lower zone wins)")
            <- forAll(validProfileGen) { profile in
                guard let result = try? ZoneCalculator.calculate(age: profile.age, restingHR: profile.restingHR) else {
                    return false
                }
                let z = result.zones
                return ZoneCalculator.zone(for: z.zone1.max, in: z) == 1
                    && ZoneCalculator.zone(for: z.zone2.max, in: z) == 2
                    && ZoneCalculator.zone(for: z.zone3.max, in: z) == 3
                    && ZoneCalculator.zone(for: z.zone4.max, in: z) == 4
            }
    }

    func testCalculateDeterministic() {
        property("same inputs always produce identical HRZones")
            <- forAll(validProfileGen) { profile in
                guard let r1 = try? ZoneCalculator.calculate(age: profile.age, restingHR: profile.restingHR),
                      let r2 = try? ZoneCalculator.calculate(age: profile.age, restingHR: profile.restingHR) else {
                    return false
                }
                return r1.zones.zone1.min == r2.zones.zone1.min
                    && r1.zones.zone5.max == r2.zones.zone5.max
            }
    }
}

// MARK: - RHRWarning Equatable (test support)
extension RHRWarning: Equatable {}
