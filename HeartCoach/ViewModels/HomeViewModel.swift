import Foundation
import HeartRateCoachCore

@Observable
final class HomeViewModel {

    var profile: UserProfileV2?
    var zones: HRZones?
    var lastSession: Session?
    var isLoading = false
    var isHealthKitAuthorized = false

    /// Today's assigned session (Phase 3). nil until the profile loads.
    var assignment: SessionAssignment?
    /// Positive re-entry message after a relapse push-back (§C), shown once.
    var relapseMessage: String?

    private let firebaseService: FirebaseServiceProtocol
    private let healthKitService: HealthKitServiceProtocol

    init(firebaseService: FirebaseServiceProtocol, healthKitService: HealthKitServiceProtocol) {
        self.firebaseService = firebaseService
        self.healthKitService = healthKitService
    }

    func loadData(userID: String) {
        isLoading = true
        recheckHealthKitStatus()
        Task {
            async let profileTask = firebaseService.loadProfileV2(userID: userID)
            async let sessionsTask = firebaseService.loadSessions(userID: userID, limit: 1)

            var p = try? await profileTask
            let sessions = (try? await sessionsTask) ?? []

            // Apply relapse push-back on open (§C), once per gap; persist if changed.
            var relapseMsg: String?
            if var profile = p, let program = profile.program {
                let (updated, outcome) = ProgressionEngine.applyRelapse(program: program, now: Date())
                if outcome.band != .none {
                    profile.program = updated
                    p = profile
                    try? await self.firebaseService.saveProfileV2(profile, userID: userID)
                    relapseMsg = Self.relapseMessage(outcome)
                }
            }
            let assignment = p.map { ProgressionEngine.assign(profile: $0) }
            let z = p.flatMap { try? $0.computeZones() }

            await MainActor.run {
                self.profile = p
                self.zones = z
                self.lastSession = sessions.first
                self.assignment = assignment
                self.relapseMessage = relapseMsg
                self.isLoading = false
            }
        }
    }

    /// Records the non-negotiable 15-min minimum: resets the relapse clock,
    /// does not advance progression (§I, BR-3-9).
    func recordMinimumWalk(userID: String) {
        guard var profile = profile, let program = profile.program else { return }
        let updated = ProgressionEngine.registerMinimumWalk(program: program, now: Date())
        profile.program = updated
        self.profile = profile
        Task { try? await firebaseService.saveProfileV2(profile, userID: userID) }
    }

    private static func relapseMessage(_ o: RelapseOutcome) -> String {
        switch o.band {
        case .resetToStart:
            return "Welcome back! We've reset your Foundation to the start so you can rebuild safely."
        case .none:
            return ""
        default:
            return "Welcome back! We've eased you back a few sessions so you return strong."
        }
    }

    func recheckHealthKitStatus() {
        isHealthKitAuthorized = healthKitService.isAuthorized
    }

    func requestHealthKitAccess() {
        Task {
            try? await healthKitService.requestAuthorization()
            await MainActor.run {
                isHealthKitAuthorized = healthKitService.isAuthorized
            }
        }
    }
}
