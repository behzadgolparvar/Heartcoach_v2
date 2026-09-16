import Foundation
import HeartRateCoachCore

@Observable
final class HomeViewModel {

    var profile: UserProfileV2?
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
            async let profileTask = firebaseService.loadProfileV2(userID: userID)
            async let sessionsTask = firebaseService.loadSessions(userID: userID, limit: 1)

            let p = try? await profileTask
            let sessions = (try? await sessionsTask) ?? []
            let z = p.flatMap { try? $0.computeZones() }

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

    func requestHealthKitAccess() {
        Task {
            try? await healthKitService.requestAuthorization()
            await MainActor.run {
                isHealthKitAuthorized = healthKitService.isAuthorized
            }
        }
    }
}
