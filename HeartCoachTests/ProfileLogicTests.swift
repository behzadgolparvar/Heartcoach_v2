import XCTest
import HeartRateCoachCore
@testable import HeartCoach

/// Phase 1 core-logic tests. Placed in the app test target (which runs cleanly) rather than
/// the core package's SwiftCheck target, which does not compile under the current toolchain.
/// Property-style coverage is via deterministic loops (partial-PBT intent).
final class ProfileLogicTests: XCTestCase {

    // MARK: - UnitConverter

    func test_weightConversion_knownValues() {
        XCTAssertEqual(UnitConverter.lbsToKg(100), 45.359237, accuracy: 1e-6)
        XCTAssertEqual(UnitConverter.kgToLbs(45.359237), 100, accuracy: 1e-6)
    }

    func test_heightConversion_knownValues() {
        XCTAssertEqual(UnitConverter.inchesToCm(10), 25.4, accuracy: 1e-9)
        XCTAssertEqual(UnitConverter.cmToInches(25.4), 10, accuracy: 1e-9)
    }

    func test_weightRoundTrip_property() {
        for kg in stride(from: 1.0, through: 500.0, by: 0.5) {
            XCTAssertEqual(UnitConverter.lbsToKg(UnitConverter.kgToLbs(kg)), kg, accuracy: 1e-6)
        }
    }

    func test_heightRoundTrip_property() {
        for cm in stride(from: 1.0, through: 300.0, by: 0.5) {
            XCTAssertEqual(UnitConverter.inchesToCm(UnitConverter.cmToInches(cm)), cm, accuracy: 1e-6)
        }
    }

    // MARK: - BMI

    func test_bmi_knownValue() throws {
        let bmi = try XCTUnwrap(BMI.calculate(weightKg: 70, heightCm: 175))
        XCTAssertEqual(bmi, 22.857, accuracy: 0.01)
    }

    func test_bmi_nilForNonPositiveHeight() {
        XCTAssertNil(BMI.calculate(weightKg: 70, heightCm: 0))
        XCTAssertNil(BMI.calculate(weightKg: 70, heightCm: -10))
    }

    func test_bmi_strictlyIncreasesWithWeight_property() {
        for w in stride(from: 30.0, through: 200.0, by: 1.0) {
            for h in stride(from: 120.0, through: 220.0, by: 5.0) {
                let a = BMI.calculate(weightKg: w, heightCm: h)!
                let b = BMI.calculate(weightKg: w + 1, heightCm: h)!
                XCTAssertGreaterThan(b, a, "BMI should rise with weight at height \(h)")
            }
        }
    }

    // MARK: - Mentality lean (exhaustive over all 8 combinations)

    func test_mentalityLean_exhaustive() {
        let drivers: [MotivationDriver] = [.process, .outcome]
        let responses: [MissedResponse] = [.habit, .goal]
        let routines: [RoutinePreference] = [.fixed, .variety]
        for d in drivers { for r in responses { for rt in routines {
            let m = Mentality(motivationDriver: d, missedResponse: r, routinePreference: rt)
            let outcomeCount = (d == .outcome ? 1 : 0) + (r == .goal ? 1 : 0) + (rt == .variety ? 1 : 0)
            let expected: MentalityLean = outcomeCount == 3 ? .outcome : (outcomeCount == 0 ? .process : .mixed)
            XCTAssertEqual(m.derivedLean, expected, "combo \(d)/\(r)/\(rt)")
        }}}
    }

    // MARK: - Profile Codable round-trip

    func test_userProfileV2_codableRoundTrip() throws {
        let profile = UserProfileV2(
            age: 32, gender: .male, weightKg: 82, heightCm: 180, unitsPreference: .metric,
            restingHR: 52, maxHROverride: nil,
            goals: [.fastWeightLoss, .cardioFitness], fitnessExperience: .intermediate,
            mentality: Mentality(motivationDriver: .outcome, missedResponse: .goal, routinePreference: .variety),
            healthHistory: HealthHistory(chronicConditions: [.none], hrMedications: [.betaBlockers], smokingStatus: .never),
            facility: FacilityInfo(equipment: [.treadmill], locationPreference: .indoor),
            device: DeviceInfo(wearable: .appleWatch, trackingApps: [.strava]),
            schedule: Schedule(sessionLengthMin: 35, frequencyPerWeek: 3, preferredDays: [.mon, .wed, .fri], preferredTimeOfDay: .morning),
            consent: Consent(healthDataConsent: true, remindersConsent: true, consentedAt: nil, consentVersion: "1.0"),
            v2Completed: true
        )
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfileV2.self, from: data)
        XCTAssertEqual(decoded, profile)
    }

    func test_effectiveMaxHR_overrideThenFormula() {
        var p = UserProfileV2(
            age: 30, gender: .preferNotToSay, unitsPreference: .metric, restingHR: 60,
            goals: [.routine], fitnessExperience: .beginner,
            mentality: Mentality(motivationDriver: .process, missedResponse: .habit, routinePreference: .fixed),
            schedule: Schedule(sessionLengthMin: 30, frequencyPerWeek: 3),
            consent: Consent(healthDataConsent: true, remindersConsent: true)
        )
        XCTAssertEqual(p.effectiveMaxHR, 190)
        p.maxHROverride = 175
        XCTAssertEqual(p.effectiveMaxHR, 175)
    }

    func test_consent_isComplete() {
        XCTAssertFalse(Consent(healthDataConsent: true, remindersConsent: false).isComplete)
        XCTAssertTrue(Consent(healthDataConsent: true, remindersConsent: true).isComplete)
    }
}
