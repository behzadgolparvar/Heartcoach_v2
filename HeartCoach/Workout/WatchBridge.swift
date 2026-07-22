import WatchConnectivity
import HeartRateCoachCore

protocol WatchBridgeProtocol: AnyObject {
    var onHRReceived: ((HRReading) -> Void)? { get set }
    func sendHaptic(_ pattern: HapticPattern)
    func sendCoachingState(_ state: CoachingState)
    func sendCommand(_ command: String)
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
        // WCSession has no explicit deactivate; clear the callback to stop processing
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
            "phase": state.phase.rawValue
        ]
        if let message = state.coachingMessage {
            payload["message"] = message
        }
        WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: { _ in })
    }

    func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["command": command],
            replyHandler: nil,
            errorHandler: { _ in }
        )
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

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
