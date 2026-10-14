import XCTest
import HeartRateCoachCore

/// BR-1b-9 + serialization round-trips (PBT partial).
final class ProfileV5CodableTests: XCTestCase {

    func test_v5Profile_codableRoundTrip() throws {
        let original = UserProfileV2.fixture
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfileV2.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertTrue(decoded.isV5Complete)
        XCTAssertEqual(decoded.program?.currentStage, .foundation)
    }

    func test_programState_withMultipleStages_roundTrips() throws {
        var program = ProgramState.newUser()
        program.stageProgress[.levelUp] = StageProgress(stage: .levelUp, sessionsCompleted: 25)
        program.currentStage = .levelUp
        var profile = UserProfileV2.fixture
        profile.program = program

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfileV2.self, from: data)
        XCTAssertEqual(decoded.program?.currentStage, .levelUp)
        XCTAssertEqual(decoded.program?.stageProgress[.levelUp]?.sessionsCompleted, 25)
        XCTAssertEqual(decoded.program?.stageProgress[.levelUp]?.subPhase, 1)
    }

    func test_preV5Json_decodesWithoutThrowing_andIsNotV5Complete() throws {
        // A Phase-1 document: no q1/q2, no classificationMismatch key, no program.
        let json = """
        {
          "age": 42,
          "gender": "male",
          "unitsPreference": "metric",
          "restingHR": 61,
          "goals": ["cardio_fitness"],
          "fitnessExperience": "intermediate",
          "mentality": { "motivationDriver": "process", "missedResponse": "habit", "routinePreference": "fixed" },
          "schedule": { "sessionLengthMin": 35, "frequencyPerWeek": 3, "preferredDays": [] },
          "consent": { "healthDataConsent": true, "remindersConsent": true, "consentVersion": "1.0" },
          "v2Completed": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UserProfileV2.self, from: json)
        XCTAssertFalse(decoded.isV5Complete)
        XCTAssertNil(decoded.q1TrainingHistory)
        XCTAssertNil(decoded.program)
        XCTAssertFalse(decoded.classificationMismatch)   // defaulted, not thrown
        XCTAssertEqual(decoded.age, 42)
    }
}
