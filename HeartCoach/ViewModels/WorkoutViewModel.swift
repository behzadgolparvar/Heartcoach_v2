import Foundation
import HeartRateCoachCore

@Observable
@MainActor
final class WorkoutViewModel {

    // MARK: - State (published to WorkoutView)

    var coachingState: CoachingState?
    var isPaused: Bool = false
    var isWorkoutActive: Bool = false
    var lastMessage: CoachingMessage?
    var completedSession: Session?
    var selectedProgram: WorkoutProgram?

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
        self.lastMessage = nil
        self.completedSession = nil
        // Wake the Watch app into a workout so HR streams without opening it manually.
        healthKitService.startWatchWorkout()
        manager.start()
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
        guard let manager = sessionManager else { return }
        let session = await manager.end()
        completedSession = session
        isWorkoutActive = false
        sessionManager = nil
    }

    @MainActor
    func emergencyStop() {
        sessionManager?.emergencyStop()
        isWorkoutActive = false
        sessionManager = nil
    }

    var isMuted: Bool {
        get { voiceFeedback.isMuted }
        set { voiceFeedback.isMuted = newValue }
    }
}
