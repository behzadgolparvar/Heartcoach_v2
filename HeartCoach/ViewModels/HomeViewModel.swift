import Foundation
import HeartRateCoachCore

@Observable
final class HomeViewModel {

    var profile: UserProfile?
    var zones: HRZones?
    var lastSession: Session?
    var isLoading = false
    var isHealthKitAuthorized = false

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
            async let profileTask = firebaseService.loadProfile(userID: userID)
            async let zonesTask = firebaseService.loadZones(userID: userID)
            async let sessionsTask = firebaseService.loadSessions(userID: userID, limit: 1)

            let (p, z, sessions) = (
                try? await profileTask,
                try? await zonesTask,
                (try? await sessionsTask) ?? []
            )

            await MainActor.run {
                self.profile = p
                self.zones = z
                self.lastSession = sessions.first
                self.isLoading = false
            }
        }
    }

    func recheckHealthKitStatus() {
        isHealthKitAuthorized = healthKitService.isAuthorized
    }
}
