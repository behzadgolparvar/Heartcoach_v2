import Foundation
import HeartRateCoachCore

/// Orchestrates a single workout session.
/// Owns the tick loop, CoachingEngineState, phase sequencing, and bridges to voice and Watch.
/// One instance per session — tear down and create anew for each workout.
@MainActor
final class WorkoutSessionManager {

    // MARK: - Dependencies

    private let voiceFeedback: VoiceFeedbackServiceProtocol
    private let watchBridge: WatchBridgeProtocol
    private let zones: HRZones

    // MARK: - Session State

    private var engineState = CoachingEngineState()
    private var sequencer: WorkoutPhaseSequencer
    private var program: WorkoutProgram
    private var sessionStartDate: Date?
    private var lastHRReceived: HRReading?
    private var hrRecords: [HRRecord] = []
    private var tickTask: Task<Void, Never>?

    // MARK: - Callback

    /// Called on every tick with the latest coaching snapshot for WorkoutViewModel.
    var onStateUpdate: ((CoachingState) -> Void)?
    /// Called when the workout completes naturally (all phases done).
    var onWorkoutComplete: (() -> Void)?

    // MARK: - Init

    init(program: WorkoutProgram,
         zones: HRZones,
         voiceFeedback: VoiceFeedbackServiceProtocol,
         watchBridge: WatchBridgeProtocol) {
        self.program = program
        self.zones = zones
        self.voiceFeedback = voiceFeedback
        self.watchBridge = watchBridge
        self.sequencer = WorkoutPhaseSequencer(program: program)
    }

    // MARK: - Lifecycle

    /// True once at least one HR reading has arrived — used by the start countdown.
    var hasReceivedHR: Bool { lastHRReceived != nil }

    /// Step 1 of starting: launch the Watch workout and begin receiving HR, without
    /// starting coaching or the workout timer yet (that happens in `beginCoaching()`
    /// after the countdown, so HR is already flowing on the first coaching tick).
    func beginWatchSession() {
        voiceFeedback.configureAudioSession()
        watchBridge.onHRReceived = { [weak self] reading in
            Task { @MainActor in
                self?.lastHRReceived = reading
            }
        }
        // Notify Watch that workout started (WCSession already activated at app launch)
        watchBridge.sendCommand("workoutStarted")
    }

    /// Step 2 of starting: begin the coaching tick loop and the workout timer.
    func beginCoaching() {
        sessionStartDate = Date()
        hrRecords = []
        engineState = CoachingEngineState()
        startTickLoop()
    }

    func pause() {
        tickTask?.cancel()
        tickTask = nil
        engineState.resetForPause()
        voiceFeedback.stopSpeaking()
    }

    func resume() {
        startTickLoop()
    }

    func end() async -> Session {
        tickTask?.cancel()
        tickTask = nil
        voiceFeedback.stopSpeaking()
        watchBridge.sendCommand("workoutStopped")
        watchBridge.deactivate()
        return buildSession()
    }

    func emergencyStop() {
        tickTask?.cancel()
        tickTask = nil
        voiceFeedback.speak(.emergencyStop)
        watchBridge.sendHaptic(.emergencyRepeated)
        watchBridge.deactivate()
    }

    // MARK: - Tick Loop

    private func startTickLoop() {
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self.processTick() }
            }
        }
    }

    private func processTick() {
        let now = Date()

        // Determine HR — use last known if stale but within 14s; Int.max if ≥15s
        let hr: Int
        if let reading = lastHRReceived {
            let staleness = now.timeIntervalSince(reading.timestamp)
            hr = staleness >= 15 ? Int.max : reading.value
        } else {
            hr = Int.max  // no reading yet
        }

        let phase = sequencer.currentPhase
        let elapsedInPhase = sequencer.totalElapsedTime -
            sequencer.phases(before: phase.index)

        // Run coaching engine
        let message = CoachingEngine.tick(
            hr: hr == Int.max ? Int.max : hr,
            phase: phase,
            elapsedInPhase: elapsedInPhase,
            state: &engineState,
            zones: zones,
            now: now
        )

        // Deliver coaching
        if let message {
            voiceFeedback.speak(message)
            if let haptic = message.hapticPattern {
                watchBridge.sendHaptic(haptic)
            }
        }

        // Record HR data point (skip if no signal)
        if hr != Int.max {
            let zone = ZoneCalculator.zone(for: hr, in: zones)
            let record = HRRecord(
                timestamp: now,
                second: Int(sequencer.totalElapsedTime),
                hr: hr,
                currentZone: zone,
                targetZone: phase.targetZone,
                phase: phase.type,
                coachingMessage: message?.text
            )
            hrRecords.append(record)
        }

        // Advance phase sequencer
        let event = sequencer.advance(by: 5)
        if case .mainWorkoutComplete = event {
            onWorkoutComplete?()
        }

        // Publish UI snapshot
        let coachingState = CoachingState(
            currentHR: hr == Int.max ? 0 : hr,
            hrSmooth: engineState.hrSmooth,
            currentZone: hr == Int.max ? 0 : (ZoneCalculator.zone(for: hr, in: zones)),
            targetZone: phase.targetZone,
            phase: phase.type,
            phaseTimeRemaining: sequencer.timeRemainingInPhase,
            elapsedTime: sequencer.totalElapsedTime,
            coachingMessage: message?.text,
            isGracePeriodActive: sequencer.isGracePeriodActive
        )
        onStateUpdate?(coachingState)
        watchBridge.sendCoachingState(coachingState)
    }

    // MARK: - Session Building

    private func buildSession() -> Session {
        let duration = Int(Date().timeIntervalSince(sessionStartDate ?? Date()))
        let hrs = hrRecords.map(\.hr)
        let avg = hrs.isEmpty ? 0 : Int(ceil(Double(hrs.reduce(0, +)) / Double(hrs.count)))

        var timeInZones: [Int: Int] = [:]
        for record in hrRecords {
            let z = record.currentZone
            if z >= 1 && z <= 5 {
                timeInZones[z, default: 0] += 5
            }
        }

        return Session(
            date: sessionStartDate ?? Date(),
            programType: program.workoutType,
            durationSec: duration,
            avgHR: avg,
            timeInZones: timeInZones,
            hrStream: hrRecords
        )
    }
}

// MARK: - WorkoutPhaseSequencer helper

private extension WorkoutPhaseSequencer {
    func phases(before index: Int) -> TimeInterval {
        // Approximate elapsed time in previous phases using total - remaining
        // totalElapsedTime - timeRemainingInPhase gives elapsed in current phase
        return totalElapsedTime - (currentPhase.duration - timeRemainingInPhase)
    }
}
