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
    private var pauseSnoozesUsed = 0
    var canSnoozePause: Bool { SafetyPolicy.canSnooze(usedSnoozes: pauseSnoozesUsed) }

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
    private let stage: TrainingStage
    private let levelUpUnlock: LevelUpUnlock?
    /// Per-session Shape choice (Option A/B + muscles), set before `start` on Shape days.
    var shapeChoice: ShapeSessionChoice?

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
        schedulePausePrompt(afterMinutes: SafetyPolicy.pausePromptMinutes)
    }

    func resume() {
        sessionManager?.resume()
        isPaused = false
        cancelPausePrompt()
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
        sessionManager?.emergencyStop()
        isWorkoutActive = false
        startupState = .running
        sessionManager = nil
    }

    var isMuted: Bool {
        get { voiceFeedback.isMuted }
        set { voiceFeedback.isMuted = newValue }
    }
}
