import Foundation
import HeartRateCoachCore

/// Composition root — creates and owns all services and ViewModels.
/// Injected into the SwiftUI environment at app startup.
@Observable
@MainActor
final class AppContainer {
    // MARK: - Services
    let authService: AuthServiceProtocol
    let firebaseService: FirebaseServiceProtocol
    let healthKitService: HealthKitServiceProtocol
    let offlineQueue: OfflineSessionQueueProtocol
    let networkMonitor: NetworkMonitor
    let voiceFeedbackService: VoiceFeedbackServiceProtocol
    let watchBridge: WatchBridgeProtocol

    // MARK: - ViewModels
    let authViewModel: AuthViewModel
    let onboardingViewModel: OnboardingViewModel
    let homeViewModel: HomeViewModel
    let settingsViewModel: SettingsViewModel
    let summaryViewModel: WorkoutSummaryViewModel
    let historyViewModel: HistoryViewModel

    init(
        authService: AuthServiceProtocol? = nil,
        firebaseService: FirebaseServiceProtocol? = nil,
        healthKitService: HealthKitServiceProtocol? = nil,
        offlineQueue: OfflineSessionQueueProtocol? = nil,
        voiceFeedbackService: VoiceFeedbackServiceProtocol? = nil,
        watchBridge: WatchBridgeProtocol? = nil
    ) {
        let monitor = NetworkMonitor()
        let queue = offlineQueue ?? CoreDataOfflineQueue()
        let firebase = firebaseService ?? FirestoreService(networkMonitor: monitor, offlineQueue: queue)
        let auth = authService ?? FirebaseAuthService()
        let hk = healthKitService ?? HealthKitService()
        let voice = voiceFeedbackService ?? VoiceFeedbackService()
        let watch = watchBridge ?? WatchBridge()

        self.networkMonitor = monitor
        self.offlineQueue = queue
        self.firebaseService = firebase
        self.authService = auth
        self.healthKitService = hk
        self.voiceFeedbackService = voice
        self.watchBridge = watch

        let authVM = AuthViewModel(authService: auth, firebaseService: firebase)
        let onboardingVM = OnboardingViewModel(firebaseService: firebase, healthKitService: hk)
        let homeVM = HomeViewModel(firebaseService: firebase, healthKitService: hk)
        let settingsVM = SettingsViewModel(firebaseService: firebase, authService: auth)
        let summaryVM = WorkoutSummaryViewModel(firebaseService: firebase)
        let historyVM = HistoryViewModel(firebaseService: firebase, offlineQueue: queue)

        // Wire onboarding completion → auth state transition
        onboardingVM.onComplete = { [weak authVM] in
            authVM?.appState = .main
        }

        self.authViewModel = authVM
        self.onboardingViewModel = onboardingVM
        self.homeViewModel = homeVM
        self.settingsViewModel = settingsVM
        self.summaryViewModel = summaryVM
        self.historyViewModel = historyVM

        // Warm up WCSession at launch so it's reachable by the time a workout starts.
        watch.activate()
    }

    /// Creates a fresh WorkoutViewModel for a new workout session.
    /// Called by WorkoutPreStartView — one instance per session.
    func makeWorkoutViewModel(zones: HRZones) -> WorkoutViewModel {
        WorkoutViewModel(
            zones: zones,
            voiceFeedback: voiceFeedbackService,
            watchBridge: watchBridge,
            healthKitService: healthKitService
        )
    }
}
