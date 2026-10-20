import Foundation
import HeartRateCoachCore
@testable import HeartCoach

final class MockWatchBridge: WatchBridgeProtocol {
    var onHRReceived: ((HRReading) -> Void)?
    var onWatchControl: ((String) -> Void)?
    var sentPaused: [Bool] = []
    func sendPaused(_ paused: Bool) { sentPaused.append(paused) }
    var sentHaptics: [HapticPattern] = []
    var sentCoachingStates: [CoachingState] = []
    var sentCommands: [String] = []
    var activateCallCount: Int = 0
    var deactivateCallCount: Int = 0

    func sendHaptic(_ pattern: HapticPattern) {
        sentHaptics.append(pattern)
    }

    var sentSessionRemainings: [Int] = []
    func sendCoachingState(_ state: CoachingState, sessionRemaining: Int) {
        sentCoachingStates.append(state)
        sentSessionRemainings.append(sessionRemaining)
    }

    func sendCommand(_ command: String) {
        sentCommands.append(command)
    }

    var sentZoneTables: [HRZones] = []
    var sentRestingHRs: [Int] = []
    func sendWorkoutStart(zones: HRZones, restingHR: Int) {
        sentCommands.append("workoutStarted")
        sentZoneTables.append(zones)
        sentRestingHRs.append(restingHR)
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
