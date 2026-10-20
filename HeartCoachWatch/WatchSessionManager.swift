import WatchConnectivity
import HealthKit
import HeartRateCoachCore

final class WatchSessionManager: NSObject, WCSessionDelegate {

    private let hrService = HRService()
    private let hapticService = HapticService()
    private weak var viewModel: WorkoutWatchViewModel?
    /// Clears a coaching message after it has been shown ~4.5s (matches the iPhone banner).
    private var messageClearItem: DispatchWorkItem?

    // MARK: - Activation

    func activate(viewModel: WorkoutWatchViewModel) {
        self.viewModel = viewModel

        // Prompt for HealthKit access at launch (foreground) so the first workout
        // has HR immediately instead of surfacing a late permission sheet mid-session.
        hrService.requestAuthorization()

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
        // Check if iPhone already sent a command before we activated.
        if let command = session.receivedApplicationContext["command"] as? String {
            handleCommand(command,
                          zoneBounds: session.receivedApplicationContext["zoneBounds"] as? [Int],
                          restingHR: session.receivedApplicationContext["restingHR"] as? Int)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let command = applicationContext["command"] as? String {
            handleCommand(command,
                          zoneBounds: applicationContext["zoneBounds"] as? [Int],
                          restingHR: applicationContext["restingHR"] as? Int)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let command = message["command"] as? String {
            handleCommand(command,
                          zoneBounds: message["zoneBounds"] as? [Int],
                          restingHR: message["restingHR"] as? Int)
            return
        }

        if let rawHaptic = message["haptic"] as? String,
           let pattern = HapticPattern(rawValue: rawHaptic) {
            hapticService.play(pattern)
            return
        }

        if let zone = message["zone"] as? Int,
           let phaseRaw = message["phase"] as? String {
            let targetZone = message["targetZone"] as? Int ?? 0
            let remaining = message["phaseRemaining"] as? Int ?? 0
            let sessionRemaining = message["sessionRemaining"] as? Int ?? 0
            let msg = (message["message"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            DispatchQueue.main.async { [weak self] in
                guard let self, let vm = self.viewModel else { return }
                vm.currentZone = zone
                vm.phaseName = phaseRaw
                vm.targetZone = targetZone
                vm.phaseRemainingSec = remaining
                vm.sessionRemainingSec = sessionRemaining
                if let msg {
                    vm.lastMessage = msg
                    self.scheduleMessageClear()
                }
            }
        }
    }

    /// Hold a coaching message ~4.5s, then clear it (so the message line goes blank
    /// between cues rather than freezing on the last one).
    private func scheduleMessageClear() {
        messageClearItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.viewModel?.lastMessage = nil }
        }
        messageClearItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5, execute: item)
    }

    // MARK: - Commands

    private func handleCommand(_ command: String, zoneBounds: [Int]? = nil, restingHR: Int? = nil) {
        switch command {
        case "workoutStarted":
            hrService.start()
            DispatchQueue.main.async { [weak self] in
                guard let vm = self?.viewModel else { return }
                vm.isWorkoutActive = true
                if let zoneBounds, zoneBounds.count == 10 { vm.zoneBounds = zoneBounds }
                if let restingHR, restingHR > 0 { vm.restingHR = restingHR }
            }
        case "workoutStopped":
            hrService.stop()
            messageClearItem?.cancel()
            DispatchQueue.main.async { [weak self] in
                guard let vm = self?.viewModel else { return }
                vm.isWorkoutActive = false
                vm.currentHR = 0
                vm.currentZone = 0
                vm.targetZone = 0
                vm.phaseRemainingSec = 0
                vm.sessionRemainingSec = 0
                vm.lastMessage = nil
                vm.zoneBounds = []
            }
        default:
            break
        }
    }
}
