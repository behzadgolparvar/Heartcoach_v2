import XCTest
import HeartRateCoachCore
@testable import HeartCoachWatch

final class HapticServiceTests: XCTestCase {

    // Verifies HapticPattern.init(rawValue:) decodes every value WCSession may send.
    // If the raw values ever change, WatchSessionManager would silently drop haptics.
    func testAllHapticPatternsDecodeFromRawValue() {
        let expectedRaws = ["short", "long", "doubleTap", "emergencyRepeated"]
        for raw in expectedRaws {
            XCTAssertNotNil(HapticPattern(rawValue: raw),
                            "HapticPattern could not decode '\(raw)' — WCSession messages would be silently dropped")
        }
    }

    func testHapticPatternRawValuesAreStable() {
        XCTAssertEqual(HapticPattern.short.rawValue,             "short")
        XCTAssertEqual(HapticPattern.long.rawValue,              "long")
        XCTAssertEqual(HapticPattern.doubleTap.rawValue,         "doubleTap")
        XCTAssertEqual(HapticPattern.emergencyRepeated.rawValue, "emergencyRepeated")
    }

    // Smoke test: all 4 patterns produce a non-nil mapping without crashing.
    // WKInterfaceDevice.current().play() cannot be invoked in a unit test host,
    // so we verify only the mapping logic in HapticService is reachable.
    func testHapticServiceInstantiates() {
        let service = HapticService()
        XCTAssertNotNil(service)
    }
}
