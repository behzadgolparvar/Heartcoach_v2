import HealthKit
import HeartRateCoachCore

final class HRService: NSObject {

    var onHRReading: ((HRReading) -> Void)?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    /// Guards against finalizing the builder more than once (stop can be called twice:
    /// the phone's "workoutStopped" and the watchdog can both fire).
    private var isFinishing = false

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
        start(with: config)
    }

    /// Begin a session with a specific configuration (e.g. the one the phone passed to
    /// startWatchApp, received via the app delegate's handle(_:)).
    func start(with config: HKWorkoutConfiguration) {
        // Authorization is normally granted at launch; this call is a no-op prompt
        // if already decided, and still begins the session once access is available.
        requestAuthorization { [weak self] ok in
            guard ok, let self else { return }
            self.beginSession(config: config)
        }
    }

    func stop() {
        // Finalize the builder so watchOS releases the workout (otherwise the app
        // stays held in the background and the face keeps the app indicator).
        // Only call `end()` when the session is still live — ending an already-ended
        // session errors AND fires no `.ended` transition, so the builder would never
        // be finalized. In that case finalize it directly here.
        guard let session else { finishBuilder(at: Date()); return }
        if session.state == .ended {
            finishBuilder(at: Date())            // already ended → finalize directly
        } else {
            session.end()                        // -> `.ended` delegate -> finishBuilder
        }
    }

    /// End data collection, finish the workout, then drop the references. Idempotent.
    private func finishBuilder(at date: Date) {
        guard !isFinishing else { return }
        isFinishing = true
        guard let builder else { session = nil; isFinishing = false; return }
        builder.endCollection(withEnd: date) { [weak self] _, _ in
            builder.finishWorkout { _, _ in
                self?.session = nil
                self?.builder = nil
                self?.isFinishing = false
            }
        }
    }

    func reconnect(to existingSession: HKWorkoutSession) {
        isFinishing = false
        session = existingSession
        builder = existingSession.associatedWorkoutBuilder()
        builder?.delegate = self
        session?.delegate = self
    }

    // MARK: - Private

    private func beginSession(config: HKWorkoutConfiguration) {
        isFinishing = false
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
                        date: Date) {
        // Finalize the builder only after the session has actually ended, so watchOS
        // releases the workout (returns to the clock / stops pinning the app).
        if toState == .ended {
            DispatchQueue.main.async { [weak self] in self?.finishBuilder(at: date) }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // If ending failed (e.g. an already-ended session), still try to finalize the
        // builder and drop our references so the app isn't left holding the session.
        DispatchQueue.main.async { [weak self] in self?.finishBuilder(at: Date()) }
    }
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
