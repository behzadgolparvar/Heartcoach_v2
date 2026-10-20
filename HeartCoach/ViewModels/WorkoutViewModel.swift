import Foundation
import HeartRateCoachCore

@Observable
@MainActor
final class WorkoutViewModel {

    // MARK: - State (published to WorkoutView)

    /// Phase of the pre-workout start sequence (smart countdown).
    enum StartupState: Equatable {
        case warmingUp          // waiting for the first HR reading (capped)
        case countdown(Int)     // 3 … 2 … 1
        case running            // coaching + timer are live
    }

    var coachingState: CoachingState?
    var isPaused: Bool = false
    var isWorkoutActive: Bool = false
    var startupState: StartupState = .running
    var lastMessage: CoachingMessage?
    var completedSession: Session?
    var selectedProgram: WorkoutProgram?

    /// True while the session is at the user-paced "ready to stretch" gate (Q8).
    var awaitingCooldownStart: Bool = false
    /// Current cooldown stretch step label, shown during the cooldown sequence.
    var cooldownStepLabel: String?

    // §J safety/edge
    /// Elevated starting HR → switched to a gentle walk session (BR-2-27).
    var walkFallbackActive: Bool = false
    /// HR signal lost for ≥20s — show a "safety paused" banner (BR-2-24).
    var sensorDropout: Bool = false
    /// Shown after 15 min paused — Continue / Finish / Need More Time (BR-2-25).
    var showPausePrompt: Bool = false
    private var pausePromptTask: Task<Void, Never>?
    /// While paused, the coaching tick stops, so the phone re-sends the paused state
    /// ~every 10s as a heartbeat — keeps the Watch's phone-gone watchdog fed so a
    /// force-quit during a pause is still detected.
    private var pauseKeepAlive: Task<Void, Never>?
    private var pauseSnoozesUsed = 0
    var canSnoozePause: Bool { SafetyPolicy.canSnooze(usedSnoozes: pauseSnoozesUsed) }

    /// HR exceeded HRmax — show the full-screen safety-stop overlay (§J). Latches true.
    var safetyStop: Bool = false
    /// HR that triggered the safety stop (for the overlay numeral before live updates).
    var safetyStopHR: Int = 0

    // Coach lower-third banner (Direction D): the most-recent message, held 4.5s,
    // classified for its bar color / kicker.
    enum MessageKind: Equatable { case speedUp, slowDown, good, phase, stretch }
    struct ActiveBanner: Equatable { let text: String; let kind: MessageKind }
    var activeBanner: ActiveBanner?
    private var bannerTask: Task<Void, Never>?
    private var lastBannerText: String?

    /// Seconds to wait for the first HR reading before starting anyway.
    private let firstReadingTimeout: TimeInterval = 8
    private var startupTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let voiceFeedback: VoiceFeedbackServiceProtocol
    private let watchBridge: WatchBridgeProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let zones: HRZones
    private let restingHR: Int
    private let maxHR: Int
    // Read-only accessors for the workout UI.
    var displayZones: HRZones { zones }
    var displayRestingHR: Int { restingHR }
    var displayMaxHR: Int { maxHR }
    private let stage: TrainingStage
    private let levelUpUnlock: LevelUpUnlock?
    /// Per-session Shape choice (Option A/B + muscles), set before `start` on Shape days.
    var shapeChoice: ShapeSessionChoice?

    // Broadcast-redesign live state (Direction D)
    var sessionProtocol: FoundationProtocol?
    var hrTrace: [(second: Int, hr: Int)] = []
    var peakHR = 0
    var liveAvgHR = 0
    var exerciseSeconds = 0
    var inTargetSeconds = 0
    private var hrSum = 0
    private var hrCount = 0

    private var sessionManager: FoundationSessionManager?

    // MARK: - Init

    init(zones: HRZones,
         restingHR: Int,
         maxHR: Int,
         stage: TrainingStage = .foundation,
         levelUpUnlock: LevelUpUnlock? = nil,
         voiceFeedback: VoiceFeedbackServiceProtocol,
         watchBridge: WatchBridgeProtocol,
         healthKitService: HealthKitServiceProtocol) {
        self.zones = zones
        self.restingHR = restingHR
        self.maxHR = maxHR
        self.stage = stage
        self.levelUpUnlock = levelUpUnlock
        self.voiceFeedback = voiceFeedback
        self.watchBridge = watchBridge
        self.healthKitService = healthKitService
    }

    // MARK: - Actions

    @MainActor
    func start(program: WorkoutProgram) {
        // Stage-specific protocol: Level Up weaves leg exercises; Shape adds Option A/B
        // + muscle-targeted weight/plyometric phases. Foundation uses its own builder.
        var override: FoundationProtocol?
        var shapeHIIT = false
        let seed = UInt64(Date().timeIntervalSince1970)
        if stage == .levelUp {
            let eligible = ExerciseSelector.eligible(bank: LegExerciseBank.all, unlock: levelUpUnlock)
            let picks = ExerciseSelector.sequence(
                eligible: eligible,
                count: LevelUpProtocolBuilder.exerciseCount(for: program.workoutType), seed: seed)
            override = LevelUpProtocolBuilder.build(type: program.workoutType, exercises: picks)
        } else if stage == .shape, let choice = shapeChoice {
            let plan = ShapeExercisePlanner.plan(choice: choice, type: program.workoutType,
                                                 legUnlock: levelUpUnlock, seed: seed)
            override = ShapeProtocolBuilder.build(type: program.workoutType, planned: plan)
            shapeHIIT = (program.workoutType == .hiit)
        }
        let manager = FoundationSessionManager(
            type: program.workoutType,
            zones: zones,
            restingHR: restingHR,
            maxHR: maxHR,
            voiceFeedback: voiceFeedback,
            watchBridge: watchBridge,
            protocolOverride: override,
            shapeHIITCadence: shapeHIIT
        )
        manager.onStateUpdate = { [weak self] state in
            self?.coachingState = state
            self?.ingest(state)
        }
        manager.onWorkoutComplete = { [weak self] in
            Task { await self?.endInternal() }
        }
        manager.onAwaitingCooldownStart = { [weak self] in
            self?.awaitingCooldownStart = true
        }
        manager.onCooldownStep = { [weak self] label in
            self?.cooldownStepLabel = label
        }
        manager.onSensorDropout = { [weak self] active in
            self?.sensorDropout = active
        }
        manager.onSafetyStop = { [weak self] hr in
            guard let self else { return }
            self.safetyStopHR = hr
            self.safetyStop = true
        }
        // Controls tapped on the Watch's swipe-left page.
        watchBridge.onWatchControl = { [weak self] control in
            Task { @MainActor in
                guard let self else { return }
                switch control {
                case "pause":  if !self.isPaused { self.pause() }
                case "resume": if self.isPaused { self.resume() }
                case "end":    self.end()
                default: break
                }
            }
        }
        self.sessionManager = manager
        self.selectedProgram = program
        self.isPaused = false
        self.isWorkoutActive = true
        self.startupState = .warmingUp
        self.lastMessage = nil
        self.completedSession = nil
        self.awaitingCooldownStart = false
        self.cooldownStepLabel = nil
        self.sensorDropout = false
        self.showPausePrompt = false
        self.pauseSnoozesUsed = 0
        self.walkFallbackActive = false
        self.sessionProtocol = nil
        self.hrTrace = []
        self.peakHR = 0; self.liveAvgHR = 0
        self.exerciseSeconds = 0; self.inTargetSeconds = 0
        self.hrSum = 0; self.hrCount = 0
        self.safetyStop = false; self.safetyStopHR = 0
        self.activeBanner = nil; self.lastBannerText = nil
        self.bannerTask?.cancel(); self.bannerTask = nil

        // Wake the Watch app into a workout so HR starts spinning up immediately,
        // then run the smart countdown before coaching begins.
        healthKitService.startWatchWorkout()
        manager.beginWatchSession()

        startupTask = Task { [weak self] in
            guard let self else { return }
            // 1) Wait for the first HR reading (capped), so coaching doesn't false-alarm.
            let deadline = Date().addingTimeInterval(self.firstReadingTimeout)
            while Date() < deadline, !manager.hasReceivedHR, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
            if Task.isCancelled { return }

            // 1b) Elevated starting HR → switch to the gentle walk_fallback (§J).
            if manager.switchToWalkFallbackIfElevated() {
                self.walkFallbackActive = true
                self.voiceFeedback.speak(CoachingMessage(layer: 3,
                    text: "Your heart rate is a little high to start. We'll do an easy walk session today instead."))
            }
            // Capture the final protocol for the HR-trace background.
            self.sessionProtocol = manager.activeProtocol

            // 2) Countdown 3 … 2 … 1.
            for n in [3, 2, 1] {
                self.startupState = .countdown(n)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
            }

            // 3) Go — start coaching + the workout timer.
            self.startupState = .running
            self.voiceFeedback.speak(.letsGo)
            manager.beginCoaching()
        }
    }

    /// User tapped "Begin" on the transition gate — start the mandatory cooldown.
    func beginCooldown() {
        awaitingCooldownStart = false
        sessionManager?.beginCooldown()
    }

    func pause() {
        sessionManager?.pause()
        isPaused = true
        watchBridge.sendPaused(true)
        startPauseKeepAlive()
        schedulePausePrompt(afterMinutes: SafetyPolicy.pausePromptMinutes)
    }

    func resume() {
        sessionManager?.resume()
        isPaused = false
        watchBridge.sendPaused(false)
        pauseKeepAlive?.cancel(); pauseKeepAlive = nil
        cancelPausePrompt()
    }

    private func startPauseKeepAlive() {
        pauseKeepAlive?.cancel()
        pauseKeepAlive = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                guard let self, self.isPaused, self.isWorkoutActive else { return }
                self.watchBridge.sendPaused(true)
            }
        }
    }

    /// "Need More Time" — snooze the resume prompt (max 3 × 10 min, BR-2-25).
    func snoozePause() {
        guard canSnoozePause else { return }
        pauseSnoozesUsed += 1
        showPausePrompt = false
        schedulePausePrompt(afterMinutes: SafetyPolicy.pauseSnoozeMinutes)
    }

    private func schedulePausePrompt(afterMinutes minutes: Int) {
        pausePromptTask?.cancel()
        pausePromptTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)
            guard let self, !Task.isCancelled, self.isPaused else { return }
            self.showPausePrompt = true
        }
    }

    private func cancelPausePrompt() {
        pausePromptTask?.cancel()
        pausePromptTask = nil
        showPausePrompt = false
    }

    func end() {
        Task { await endInternal() }
    }

    @MainActor
    private func endInternal() async {
        startupTask?.cancel()
        startupTask = nil
        cancelPausePrompt()
        pauseKeepAlive?.cancel(); pauseKeepAlive = nil
        guard let manager = sessionManager else { return }
        let session = await manager.end()
        completedSession = session
        isWorkoutActive = false
        startupState = .running
        sessionManager = nil
    }

    @MainActor
    func emergencyStop() {
        startupTask?.cancel()
        startupTask = nil
        cancelPausePrompt()
        pauseKeepAlive?.cancel(); pauseKeepAlive = nil
        sessionManager?.emergencyStop()
        isWorkoutActive = false
        startupState = .running
        sessionManager = nil
    }

    var isMuted: Bool {
        get { voiceFeedback.isMuted }
        set { voiceFeedback.isMuted = newValue }
    }

    // MARK: - Broadcast-redesign derived state

    private func ingest(_ state: CoachingState) {
        // Coach banner: a fresh message slides in and holds 4.5s (independent of HR).
        if let msg = state.coachingMessage, !msg.isEmpty, msg != lastBannerText {
            lastBannerText = msg
            activeBanner = ActiveBanner(text: msg, kind: Self.classify(msg))
            bannerTask?.cancel()
            bannerTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 4_500_000_000)
                guard !Task.isCancelled else { return }
                self?.activeBanner = nil
                self?.lastBannerText = nil
            }
        }

        let sec = Int(state.elapsedTime)
        guard state.currentHR > 0 else { return }
        hrSum += state.currentHR; hrCount += 1
        liveAvgHR = Int((Double(hrSum) / Double(max(1, hrCount))).rounded())
        peakHR = max(peakHR, state.currentHR)
        if hrTrace.last?.second != sec, sec % 5 == 0 { hrTrace.append((sec, state.currentHR)) }
        if state.phase == .warmup || state.phase == .exercise {
            exerciseSeconds += 1
            if let tz = state.targetZone, let band = zones.zone(number: tz),
               (band.min...band.max).contains(state.currentHR) {
                inTargetSeconds += 1
            }
        }
    }

    /// Classify a coaching message into its Direction-D banner type (bar color / kicker).
    /// Text-based: the coaching pipeline carries only the message string to the UI.
    nonisolated static func classify(_ text: String) -> MessageKind {
        let t = text.lowercased()
        if t.contains("stretch") { return .stretch }
        if t.contains("slow") { return .slowDown }
        if t.contains("speed up") || t.contains("faster") || t.contains("pick it up")
            || t.contains("push") || t.contains("quicker") || t.contains("bit harder") { return .speedUp }
        if t.contains("good") || t.contains("great") || t.contains("nice") || t.contains("perfect")
            || t.contains("keep going") || t.contains("keep it up") || t.contains("excellent")
            || t.contains("steady") || t.contains("on track") { return .good }
        return .phase
    }

    /// % of exercise seconds spent in the target zone (for the stats row).
    var inTargetPercent: Int {
        exerciseSeconds > 0 ? Int((Double(inTargetSeconds) / Double(exerciseSeconds) * 100).rounded()) : 0
    }

    /// Total session seconds (incl. cooldown) and remaining, from the protocol.
    var totalSessionSec: Int {
        (sessionProtocol?.phases.compactMap { $0.durationSec }.reduce(0, +)) ?? 0
    }
    var remainingSessionSec: Int {
        max(0, totalSessionSec - Int(coachingState?.elapsedTime ?? 0))
    }

    /// A round/segment label for the trace caption ("ROUND 4 / 15", "BLOCK 2 / 7", …).
    var roundLabel: String {
        guard let proto = sessionProtocol, let state = coachingState else { return "" }
        let now = Int(state.elapsedTime)
        // Find the current phase by cumulative time.
        var start = 0
        for phase in proto.phases {
            let dur = phase.durationSec ?? 0
            if now < start + dur { return label(for: phase, in: proto) }
            start += dur
        }
        return proto.phases.last.map { label(for: $0, in: proto) } ?? ""
    }

    private func label(for phase: FoundationPhase, in proto: FoundationProtocol) -> String {
        switch phase.kind {
        case .warmup: return "WARM-UP"
        case .work:
            let total = proto.phases.filter { $0.kind == .work }.count
            let n = proto.phases.filter { $0.kind == .work && $0.index <= phase.index }.count
            return "ROUND \(n) / \(total)"
        case .block:
            let total = proto.phases.filter { $0.kind == .block || $0.kind == .warmup }.count
            let n = proto.phases.filter { ($0.kind == .block || $0.kind == .warmup) && $0.index <= phase.index }.count
            return "BLOCK \(n) / \(total)"
        case .exercise: return "EXERCISE"
        case .rest: return "RECOVERY"
        case .buffer: return "COOL-DOWN WALK"
        case .transition: return "READY TO STRETCH"
        case .cooldown:
            let total = proto.phases.filter { $0.kind == .cooldown }.count
            let n = proto.phases.filter { $0.kind == .cooldown && $0.index <= phase.index }.count
            return "STRETCH \(n) / \(total)"
        }
    }
}
