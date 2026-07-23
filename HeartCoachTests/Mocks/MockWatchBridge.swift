import Foundation
import HeartRateCoachCore
@testable import HeartCoach

final class MockWatchBridge: WatchBridgeProtocol {
    var onHRReceived: ((HRReading) -> Void)?
    var sentHaptics: [HapticPattern] = []
    var sentCoachingStates: [CoachingState] = []
    var sentCommands: [String] = []
    var activateCallCount: Int = 0
    var deactivateCallCount: Int = 0

    func sendHaptic(_ pattern: HapticPattern) {
        sentHaptics.append(pattern)
    }

    func sendCoachingState(_ state: CoachingState) {
        sentCoachingStates.append(state)
    }

    func sendCommand(_ command: String) {
        sentCommands.append(command)
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
