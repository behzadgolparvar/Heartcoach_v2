import WatchConnectivity
import HeartRateCoachCore

protocol WatchBridgeProtocol: AnyObject {
    var onHRReceived: ((HRReading) -> Void)? { get set }
    func sendHaptic(_ pattern: HapticPattern)
    func sendCoachingState(_ state: CoachingState)
    func sendCommand(_ command: String)
    /// Starts the Watch workout and ships the (static) HR zone table + resting HR so the
    /// Watch can position its gauge marker within the current block from its live HR.
    func sendWorkoutStart(zones: HRZones, restingHR: Int)
    func activate()
    func deactivate()
}

final class WatchBridge: NSObject, WatchBridgeProtocol, WCSessionDelegate {

    var onHRReceived: ((HRReading) -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func deactivate() {
        onHRReceived = nil
    }

    func sendHaptic(_ pattern: HapticPattern) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["haptic": pattern.rawValue],
            replyHandler: nil,
            errorHandler: { _ in }
        )
    }

    func sendCoachingState(_ state: CoachingState) {
        guard WCSession.default.isReachable else { return }
        var payload: [String: Any] = [
            "zone": state.currentZone,
            "phase": state.phase.rawValue,
            "phaseRemaining": max(0, Int(state.phaseTimeRemaining))
        ]
        if let tz = state.targetZone { payload["targetZone"] = tz }
        if let message = state.coachingMessage {
            payload["message"] = message
        }
        WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: { _ in })
    }

    func sendCommand(_ command: String) {
        let payload: [String: Any] = ["command": command, "ts": Date().timeIntervalSince1970]
        // updateApplicationContext is guaranteed delivery — Watch receives it on next open.
        try? WCSession.default.updateApplicationContext(payload)
        // sendMessage is the fast path if the Watch is already reachable.
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["command": command],
                replyHandler: nil,
                errorHandler: { _ in }
            )
        }
    }

    func sendWorkoutStart(zones: HRZones, restingHR: Int) {
        let bounds = Self.flatBounds(zones)   // [z1.min,z1.max, … z5.min,z5.max]
        let payload: [String: Any] = ["command": "workoutStarted",
                                      "zoneBounds": bounds,
                                      "restingHR": restingHR,
                                      "ts": Date().timeIntervalSince1970]
        // Guaranteed delivery: the Watch gets the bounds on next open / reconnect.
        try? WCSession.default.updateApplicationContext(payload)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["command": "workoutStarted",
                                           "zoneBounds": bounds, "restingHR": restingHR],
                                          replyHandler: nil, errorHandler: { _ in })
        }
    }

    /// Flattens the zone table to the 10 ints the Watch marker needs.
    private static func flatBounds(_ z: HRZones) -> [Int] {
        [z.zone1.min, z.zone1.max, z.zone2.min, z.zone2.max, z.zone3.min,
         z.zone3.max, z.zone4.min, z.zone4.max, z.zone5.min, z.zone5.max]
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    func sessionReachabilityDidChange(_ session: WCSession) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let bpm = message["hr"] as? Int else { return }
        let reading = HRReading(value: bpm)
        DispatchQueue.main.async { [weak self] in
            self?.onHRReceived?(reading)
        }
    }
}
