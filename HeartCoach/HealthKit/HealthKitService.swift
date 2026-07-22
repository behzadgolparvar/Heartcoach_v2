import Foundation
import HealthKit

final class HealthKitService: HealthKitServiceProtocol {

    private let store = HKHealthStore()
    private let hrType = HKQuantityType(.heartRate)

    /// True when the user has granted heart rate read access.
    var isAuthorized: Bool {
        HKHealthStore.isHealthDataAvailable() &&
        store.authorizationStatus(for: hrType) == .sharingAuthorized
    }

    /// Requests heart rate read authorization from the user.
    /// iOS shows the system permission dialog on first call; subsequent calls return silently.
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AppError.healthKitUnauthorized
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [hrType])
        } catch {
            throw AppError.healthKitUnauthorized
        }
    }
}
