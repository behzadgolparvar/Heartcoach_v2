import Foundation
import HeartRateCoachCore
@testable import HeartCoach

final class MockWatchBridge: WatchBridgeProtocol {
    var onHRReceived: ((HRReading) -> Void)?
    var sentHaptics: [HapticPattern] = []
    var activateCallCount: Int = 0
    var deactivateCallCount: Int = 0

    func sendHaptic(_ pattern: HapticPattern) {
        sentHaptics.append(pattern)
    }

    func activate() {
        activateCallCount += 1
    }

    func deactivate() {
        deactivateCallCount += 1
    }

    func simulateHRReading(_ reading: HRReading) {
        onHRReceived?(reading)
    }
}
