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

    /// Seconds to wait for the first HR reading before starting anyway.
    private let firstReadingTimeout: TimeInterval = 8
    private var startupTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let voiceFeedback: VoiceFeedbackServiceProtocol
    private let watchBridge: WatchBridgeProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let zones: HRZones

    private var sessionManager: WorkoutSessionManager?

    // MARK: - Init

    init(zones: HRZones,
         voiceFeedback: VoiceFeedbackServiceProtocol,
         watchBridge: WatchBridgeProtocol,
         healthKitService: HealthKitServiceProtocol) {
        self.zones = zones
        self.voiceFeedback = voiceFeedback
        self.watchBridge = watchBridge
        self.healthKitService = healthKitService
    }

    // MARK: - Actions

    @MainActor
    func start(program: WorkoutProgram) {
        let manager = WorkoutSessionManager(
            program: program,
            zones: zones,
            voiceFeedback: voiceFeedback,
            watchBridge: watchBridge
        )
        manager.onStateUpdate = { [weak self] state in
            self?.coachingState = state
        }
        manager.onWorkoutComplete = { [weak self] in
            Task { await self?.endInternal() }
        }
        self.sessionManager = manager
        self.selectedProgram = program
        self.isPaused = false
        self.isWorkoutActive = true
        self.startupState = .warmingUp
        self.lastMessage = nil
        self.completedSession = nil

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
