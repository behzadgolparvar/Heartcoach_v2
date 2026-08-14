import Foundation
import HealthKit

final class HealthKitService: HealthKitServiceProtocol {

    private let store = HKHealthStore()
    private let hrType = HKQuantityType(.heartRate)
    private let rhrType = HKQuantityType(.restingHeartRate)
    // Bumped to _v2 so existing users re-prompt once and grant workout sharing,
    // which iOS requires to launch a workout on the paired Watch.
    private static let authKey = "healthkit_auth_requested_v2"

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
            try await store.requestAuthorization(
                toShare: [HKObjectType.workoutType()],
                read: [hrType, rhrType]
            )
            UserDefaults.standard.set(true, forKey: Self.authKey)
        } catch {
            throw AppError.healthKitUnauthorized
        }
    }

    func startWatchWorkout() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown
        store.startWatchApp(with: config) { _, error in
            #if DEBUG
            if let error {
                print("[Watch] startWatchApp failed: \(error.localizedDescription)")
            }
            #endif
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
