import WatchConnectivity
import HealthKit
import HeartRateCoachCore

final class WatchSessionManager: NSObject, WCSessionDelegate {

    /// Shared so the WKApplicationDelegate (which receives the phone-launched workout)
    /// and the app's view both drive the same session.
    static let shared = WatchSessionManager()

    private let hrService = HRService()
    private let hapticService = HapticService()
    private weak var viewModel: WorkoutWatchViewModel?
    /// Clears a coaching message after it has been shown ~4.5s (matches the iPhone banner).
    private var messageClearItem: DispatchWorkItem?

    // MARK: - Phone-gone watchdog
    // The phone heartbeats while a workout runs (coaching state ~5s; a keepalive ~10s
    // while paused). If we hear nothing for `watchdogTimeout`, the phone was force-quit
    // or crashed, so end the Watch session and return to idle (iOS can't tell us directly).
    private var lastPhoneContactAt = Date()
    private var watchdog: Timer?
    private let watchdogTimeout: TimeInterval = 25
    /// True between start and teardown. Guards against duplicate commands: the phone
    /// sends each command via BOTH updateApplicationContext and sendMessage, so
    /// "workoutStarted"/"workoutStopped" arrive twice — without this we'd start two
    /// sessions and call `end()` twice (the "Failed to end from Ended(3)" error).
    private var workoutRunning = false

    // MARK: - Activation

    func activate(viewModel: WorkoutWatchViewModel) {
        self.viewModel = viewModel
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            viewModel.onControl = { control in self.sendControl(control) }
            // Sync in case handle(_:) already began the workout before the view appeared.
            viewModel.isWorkoutActive = self.workoutRunning
        }

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

    /// Begin the workout the phone launched (via startWatchApp → handle), or a default
    /// one as a fallback from the WCSession command. Idempotent — the duplicate path is
    /// a no-op. Starting from the phone-provided config lets watchOS release the workout
    /// assertion when we end, so the app doesn't linger in the background.
    func beginWorkout(with config: HKWorkoutConfiguration?) {
        guard !workoutRunning else { return }
        workoutRunning = true
        if let config { hrService.start(with: config) } else { hrService.start() }
        startWatchdog()
        DispatchQueue.main.async { [weak self] in self?.viewModel?.isWorkoutActive = true }
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

    /// Send a controls-page action to the phone ("pause" / "resume" / "end").
    private func sendControl(_ control: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["control": control], replyHandler: nil, errorHandler: { _ in })
    }

    // MARK: - Session Recovery

    private func recoverIfNeeded() {
        HKHealthStore().recoverActiveWorkoutSession { [weak self] session, _ in
            guard let self, let session else { return }
            self.workoutRunning = true
            self.hrService.reconnect(to: session)
            // Watch the recovered session too: if the phone isn't driving it (gone /
            // orphaned), the watchdog ends it after `watchdogTimeout` instead of
            // letting it live on in the background forever.
            self.startWatchdog()
            DispatchQueue.main.async {
                self.viewModel?.isWorkoutActive = true
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
        notePhoneContact()
        if let command = applicationContext["command"] as? String {
            handleCommand(command,
                          zoneBounds: applicationContext["zoneBounds"] as? [Int],
                          restingHR: applicationContext["restingHR"] as? Int)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        notePhoneContact()
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

        if let paused = message["paused"] as? Bool {
            DispatchQueue.main.async { [weak self] in self?.viewModel?.isPaused = paused }
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
            // Session start is driven by handle(_:) with the phone-launched config, so we
            // adopt the system's workout (and release its assertion on end). This command
            // only carries the zone table + resting HR. A delayed fallback starts a default
            // session only if handle(_:) never fired — it must NOT pre-empt handle, or the
            // real config is lost and the workout assertion lingers (stuck face icon).
            DispatchQueue.main.async { [weak self] in
                guard let vm = self?.viewModel else { return }
                if let zoneBounds, zoneBounds.count == 10 { vm.zoneBounds = zoneBounds }
                if let restingHR, restingHR > 0 { vm.restingHR = restingHR }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.beginWorkout(with: nil)   // no-op if handle already started it
            }
        case "workoutStopped":
            teardownWorkout()
        default:
            break
        }
    }

    // MARK: - Watchdog

    private func notePhoneContact() { lastPhoneContactAt = Date() }

    private func startWatchdog() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lastPhoneContactAt = Date()
            self.watchdog?.invalidate()
            self.watchdog = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                guard let self else { return }
                if Date().timeIntervalSince(self.lastPhoneContactAt) > self.watchdogTimeout {
                    self.teardownWorkout()   // phone force-quit / crashed
                }
            }
        }
    }

    /// End the Watch session and return to idle. Safe to call from the watchdog or a
    /// phone "workoutStopped" — idempotent.
    private func teardownWorkout() {
        guard workoutRunning else { return }   // already torn down (duplicate / race)
        workoutRunning = false
        hrService.stop()
        messageClearItem?.cancel()
        DispatchQueue.main.async { [weak self] in
            self?.watchdog?.invalidate(); self?.watchdog = nil
            guard let vm = self?.viewModel else { return }
            vm.isWorkoutActive = false
            vm.isPaused = false
            vm.currentHR = 0
            vm.currentZone = 0
            vm.targetZone = 0
            vm.phaseRemainingSec = 0
            vm.sessionRemainingSec = 0
            vm.lastMessage = nil
            vm.zoneBounds = []
        }
    }
}
