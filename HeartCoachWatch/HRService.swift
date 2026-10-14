import HealthKit
import HeartRateCoachCore

final class HRService: NSObject {

    var onHRReading: ((HRReading) -> Void)?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private let hrType = HKQuantityType(.heartRate)
    private let bpmUnit = HKUnit.count().unitDivided(by: .minute())

    // MARK: - Lifecycle

    /// Request HealthKit authorization up-front (at Watch-app launch) so the
    /// permission sheet appears before the first workout — not mid-session, which
    /// delays HR and shows a false "no signal" banner on the phone. Safe to call on
    /// every launch: if access is already decided, HealthKit returns without a prompt.
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        guard HKHealthStore.isHealthDataAvailable() else { completion?(false); return }
        let typesToShare: Set<HKSampleType> = [HKQuantityType(.heartRate),
                                                HKQuantityType.workoutType()]
        let typesToRead: Set<HKObjectType> = [HKQuantityType(.heartRate)]
        store.requestAuthorization(toShare: typesToShare, read: typesToRead) { ok, _ in
            DispatchQueue.main.async { completion?(ok) }
        }
    }

    func start() {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown
        // Authorization is normally granted at launch; this call is a no-op prompt
        // if already decided, and still begins the session once access is available.
        requestAuthorization { [weak self] ok in
            guard ok, let self else { return }
            self.beginSession(config: config)
        }
    }

    func stop() {
        session?.end()
        builder?.finishWorkout { _, _ in }
    }

    func reconnect(to existingSession: HKWorkoutSession) {
        session = existingSession
        builder = existingSession.associatedWorkoutBuilder()
        builder?.delegate = self
        session?.delegate = self
    }

    // MARK: - Private

    private func beginSession(config: HKWorkoutConfiguration) {
        do {
            let ws = try HKWorkoutSession(healthStore: store, configuration: config)
            let wb = ws.associatedWorkoutBuilder()
            ws.delegate = self
            wb.delegate = self
            wb.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            session = ws
            builder = wb
            ws.startActivity(with: Date())
            wb.beginCollection(withStart: Date()) { _, _ in }
        } catch {
            // HealthKit unavailable on this device — no-op
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension HRService: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension HRService: HKLiveWorkoutBuilderDelegate {

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard collectedTypes.contains(hrType) else { return }
        guard let stats = workoutBuilder.statistics(for: hrType),
              let bpmQ = stats.mostRecentQuantity() else { return }
        let bpm = Int(bpmQ.doubleValue(for: bpmUnit))
        let reading = HRReading(value: bpm)
        DispatchQueue.main.async { [weak self] in
            self?.onHRReading?(reading)
        }
    }
}
