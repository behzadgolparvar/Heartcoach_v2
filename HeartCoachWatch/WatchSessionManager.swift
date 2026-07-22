import WatchConnectivity
import HealthKit
import HeartRateCoachCore

final class WatchSessionManager: NSObject, WCSessionDelegate {

    private let hrService = HRService()
    private let hapticService = HapticService()
    private weak var viewModel: WorkoutWatchViewModel?

    // MARK: - Activation

    func activate(viewModel: WorkoutWatchViewModel) {
        self.viewModel = viewModel

        hrService.onHRReading = { [weak self] reading in
            self?.sendHR(reading)
            DispatchQueue.main.async {
                viewModel.currentHR = reading.value
            }
        }

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Outgoing

    private func sendHR(_ reading: HRReading) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["hr": reading.value],
            replyHandler: nil,
            errorHandler: { _ in }
        )
    }

    // MARK: - Session Recovery

    private func recoverIfNeeded() {
        HKHealthStore().recoverActiveWorkoutSession { [weak self] session, _ in
            guard let session else { return }
            self?.hrService.reconnect(to: session)
            DispatchQueue.main.async {
                self?.viewModel?.isWorkoutActive = true
            }
        }
    }

    // MARK: - WCSessionDelegate (watchOS — no inactive/deactivate callbacks)

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        guard activationState == .activated else { return }
        recoverIfNeeded()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let command = message["command"] as? String {
            handleCommand(command)
            return
        }

        if let rawHaptic = message["haptic"] as? String,
           let pattern = HapticPattern(rawValue: rawHaptic) {
            hapticService.play(pattern)
            return
        }

        if let zone = message["zone"] as? Int,
           let phaseRaw = message["phase"] as? String {
            let msg = message["message"] as? String
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.currentZone = zone
                self?.viewModel?.phaseName = phaseRaw.capitalized
                self?.viewModel?.lastMessage = msg
            }
        }
    }

    // MARK: - Commands

    private func handleCommand(_ command: String) {
        switch command {
        case "workoutStarted":
            hrService.start()
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.isWorkoutActive = true
            }
        case "workoutStopped":
            hrService.stop()
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.isWorkoutActive = false
                self?.viewModel?.currentHR = 0
                self?.viewModel?.currentZone = 0
                self?.viewModel?.lastMessage = nil
            }
        default:
            break
        }
    }
}
