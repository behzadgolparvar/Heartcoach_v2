import Foundation
import HealthKit

final class HealthKitService: HealthKitServiceProtocol {

    private let store = HKHealthStore()
    private let hrType = HKQuantityType(.heartRate)
    private let rhrType = HKQuantityType(.restingHeartRate)
    private static let authKey = "healthkit_auth_requested"

    // Apple doesn't expose read-only auth status — persist a flag after the dialog is shown.
    var isAuthorized: Bool {
        HKHealthStore.isHealthDataAvailable() &&
        UserDefaults.standard.bool(forKey: Self.authKey)
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw AppError.healthKitUnauthorized
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [hrType, rhrType])
            UserDefaults.standard.set(true, forKey: Self.authKey)
        } catch {
            throw AppError.healthKitUnauthorized
        }
    }

    func fetchRestingHeartRate() async -> Int? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: rhrType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: Int(bpm.rounded()))
            }
            self.store.execute(query)
        }
    }
}
