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
        self.sessionManager = manager
        self.selectedProgram = program
        self.isPaused = false
        self.isWorkoutActive = true
        self.startupState = .warmingUp
        self.lastMessage = nil
        self.completedSession = nil
        self.awaitingCooldownStart = false
        self.cooldownStepLabel = nil

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
    }

    func resume() {
        sessionManager?.resume()
        isPaused = false
    }

    func end() {
        Task { await endInternal() }
    }

    @MainActor
    private func endInternal() async {
        startupTask?.cancel()
        startupTask = nil
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
