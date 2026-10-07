import Foundation
import HeartRateCoachCore

/// Orchestrates a single v5 Foundation session: drives the `FoundationProtocol`
/// timeline, CoachingEngine v2, the mandatory cooldown (with the user-paced
/// transition gate), and end-of-training scoring. One instance per session.
///
/// Mirrors the v1 `WorkoutSessionManager` lifecycle so `WorkoutViewModel` can
/// drive it with minimal change. The v1 manager/engine are left intact (Q6=A).
@MainActor
final class FoundationSessionManager {

    // MARK: - Dependencies
    private let voiceFeedback: VoiceFeedbackServiceProtocol
    private let watchBridge: WatchBridgeProtocol
    private let zones: HRZones
    private let restingHR: Int
    private let maxHR: Int

    // MARK: - Protocol + coaching
    private let proto: FoundationProtocol
    private let type: WorkoutType
    private let escalationThresholdSec: Int
    private var coaching: CoachingSessionState

    // MARK: - Session state
    private var phaseIndex = 0
    private var elapsedInPhaseSec = 0
    private var trainingElapsedSec = 0
    private var totalElapsedSec = 0
    private var lastHRReceived: HRReading?
    private var hrRecords: [HRRecord] = []
    private var scoredSamples: [HRSample] = []
    private var sessionStartDate: Date?
    private var finalScore: SessionScore?
    private var cooldownSkipped = false
    private var tickTask: Task<Void, Never>?

    private let tickInterval = 5   // seconds per tick (safety cadence); coaching every 15s

    // MARK: - Callbacks
    var onStateUpdate: ((CoachingState) -> Void)?
    var onWorkoutComplete: (() -> Void)?      // fires after cooldown finishes
    var onAwaitingCooldownStart: (() -> Void)?
    var onCooldownStep: ((String) -> Void)?

    init(type: WorkoutType, zones: HRZones, restingHR: Int, maxHR: Int,
         voiceFeedback: VoiceFeedbackServiceProtocol, watchBridge: WatchBridgeProtocol) {
        self.type = type
        self.zones = zones
        self.restingHR = restingHR
        self.maxHR = maxHR
        self.voiceFeedback = voiceFeedback
        self.watchBridge = watchBridge
        self.proto = FoundationProtocolBuilder.build(type: type)
        self.escalationThresholdSec = CoachingEngineV2.escalationThreshold(for: type)
        self.coaching = CoachingSessionState(seed: UInt64(Date().timeIntervalSince1970))
    }

    // MARK: - Lifecycle
    var hasReceivedHR: Bool { lastHRReceived != nil }

    func beginWatchSession() {
        voiceFeedback.configureAudioSession()
        watchBridge.onHRReceived = { [weak self] reading in
            Task { @MainActor in self?.lastHRReceived = reading }
        }
        watchBridge.sendCommand("workoutStarted")
    }

    func beginCoaching() {
        sessionStartDate = Date()
        hrRecords = []
        scoredSamples = []
        startTickLoop()
    }

    func pause() {
        tickTask?.cancel(); tickTask = nil
        voiceFeedback.stopSpeaking()
    }

    func resume() { startTickLoop() }

    func end() async -> Session {
        tickTask?.cancel(); tickTask = nil
        let session = buildSession()
        // Tier-matched spoken closing (BR-2-15); keep the audio session alive for it.
        let tier = session.scoreTier ?? .needsWork
        voiceFeedback.speak(CoachingMessage(layer: 3, text: coaching.nextPhrase(tier.closingCategory)))
        watchBridge.sendCommand("workoutStopped")
        watchBridge.deactivate()
        return session
    }

    func emergencyStop() {
        tickTask?.cancel(); tickTask = nil
        voiceFeedback.speak(.emergencyStop)
        watchBridge.sendHaptic(.emergencyRepeated)
        watchBridge.deactivate()
    }

    /// Called by the UI when the user taps "Begin" on the transition gate (Q8).
    func beginCooldown() {
        // Advance past the transition phase into the first cooldown step.
        if phaseIndex < proto.phases.count, proto.phases[phaseIndex].kind == .transition {
            phaseIndex += 1
            elapsedInPhaseSec = 0
            announceCooldownStepIfNeeded()
        }
        startTickLoop()
    }

    // MARK: - Tick loop
    private func startTickLoop() {
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.processTick() }
            }
        }
    }

    private func processTick() {
        guard phaseIndex < proto.phases.count else { onWorkoutComplete?(); return }
        let phase = proto.phases[phaseIndex]
        let now = Date()

        // Transition gate: stop ticking and wait for the user's "Begin" tap.
        if phase.kind == .transition {
            finalizeTrainingScoreIfNeeded()
            tickTask?.cancel(); tickTask = nil
            onAwaitingCooldownStart?()
            return
        }

        // Determine HR (stale ≥15s or no reading → no signal).
        let hr: Int
        if let reading = lastHRReceived {
            hr = now.timeIntervalSince(reading.timestamp) >= 15 ? Int.max : reading.value
        } else { hr = Int.max }

        // Safety (every tick): HR above HRmax.
        if hr != Int.max, hr > maxHR {
            voiceFeedback.speak(.criticalSlowDown)
            watchBridge.sendHaptic(.long)
        }

        var cueText: String?
        if phase.isHRCoached, let target = phase.target, elapsedInPhaseSec % 15 == 0, hr != Int.max {
            let bpm = target.bpmRange(restingHR: restingHR, maxHR: maxHR)
            let tick = CoachingEngineV2.Tick(
                hr: hr, phase: phase, bpmTarget: bpm,
                phaseElapsedSec: elapsedInPhaseSec, phaseDurationSec: phase.durationSec,
                isPhaseStart: elapsedInPhaseSec == 0, itemsLeft: remainingScoredPhases(),
                escalationThresholdSec: escalationThresholdSec, sessionSec: totalElapsedSec,
                secondsPerTick: 15)
            if let cue = CoachingEngineV2.tick(tick, state: &coaching) {
                cueText = cue.text
                voiceFeedback.speak(CoachingMessage(layer: 2, text: cue.text, hapticPattern: cue.haptic))
                if let h = cue.haptic { watchBridge.sendHaptic(h) }
            }
        }

        // Record + score (scored phases only count toward the score).
        if hr != Int.max {
            let zone = ZoneCalculator.zone(for: hr, in: zones)
            hrRecords.append(HRRecord(
                timestamp: now, second: totalElapsedSec, hr: hr, currentZone: zone,
                targetZone: representativeZone(for: phase), phase: mapPhaseType(phase.kind),
                phaseKind: phase.kind, coachingMessage: cueText))
            if phase.kind.isScored { scoredSamples.append(HRSample(phaseIndex: phaseIndex, hr: hr)) }
        }

        publishSnapshot(hr: hr, phase: phase, cue: cueText)

        // Advance time.
        elapsedInPhaseSec += tickInterval
        totalElapsedSec += tickInterval
        if phase.kind.isScored { trainingElapsedSec += tickInterval }

        if let dur = phase.durationSec, elapsedInPhaseSec >= dur {
            advancePhase()
        }
    }

    private func advancePhase() {
        phaseIndex += 1
        elapsedInPhaseSec = 0
        guard phaseIndex < proto.phases.count else { onWorkoutComplete?(); return }
        let next = proto.phases[phaseIndex]
        if next.kind == .cooldown { announceCooldownStepIfNeeded() }
    }

    private func announceCooldownStepIfNeeded() {
        guard phaseIndex < proto.phases.count else { return }
        let phase = proto.phases[phaseIndex]
        guard phase.kind == .cooldown else { return }
        let stepOrdinal = proto.phases[..<phaseIndex].filter { $0.kind == .cooldown }.count
        if stepOrdinal < CooldownStep.allCases.count {
            let step = CooldownStep.allCases[stepOrdinal]
            voiceFeedback.speak(CoachingMessage(layer: 3, text: step.voiceCue))
            onCooldownStep?(step.label)
        }
    }

    // MARK: - Scoring / session
    private func finalizeTrainingScoreIfNeeded() {
        guard finalScore == nil else { return }
        finalScore = SessionScorer.score(protocol: proto, samples: scoredSamples,
                                         restingHR: restingHR, maxHR: maxHR, zones: zones)
    }

    private func buildSession() -> Session {
        finalizeTrainingScoreIfNeeded()
        // If training never reached the gate, score what we have.
        let score = finalScore ?? SessionScorer.score(protocol: proto, samples: scoredSamples,
                                                       restingHR: restingHR, maxHR: maxHR, zones: zones)
        let hrs = hrRecords.map(\.hr)
        let avg = hrs.isEmpty ? 0 : Int((Double(hrs.reduce(0, +)) / Double(hrs.count)).rounded(.up))
        // Mark cooldown skipped if we finalized before the last cooldown phase ran.
        let reachedEnd = phaseIndex >= proto.phases.count
        return Session(
            date: sessionStartDate ?? Date(), programType: type,
            durationSec: totalElapsedSec, avgHR: avg,
            timeInZones: score.timeInZoneSec, hrStream: hrRecords,
            scorePercent: score.percentInTarget, scoreTier: score.tier,
            trainingDurationSec: trainingElapsedSec, sessionFlag: type.rawValue,
            cooldownSkipped: !reachedEnd)
    }

    // MARK: - Helpers
    private func remainingScoredPhases() -> Int {
        proto.phases[phaseIndex...].filter { $0.kind.isScored }.count - 1
    }

    private func representativeZone(for phase: FoundationPhase) -> Int? {
        guard let target = phase.target else { return nil }
        let bpm = target.bpmRange(restingHR: restingHR, maxHR: maxHR)
        let mid = (bpm.lowerBound + bpm.upperBound) / 2
        return ZoneCalculator.zone(for: mid, in: zones)
    }

    private func mapPhaseType(_ kind: PhaseKind) -> PhaseType {
        switch kind {
        case .warmup: return .warmup
        case .block, .work: return .exercise
        case .rest: return .recovery
        case .buffer, .transition, .cooldown: return .cooldown
        }
    }

    private func publishSnapshot(hr: Int, phase: FoundationPhase, cue: String?) {
        let state = CoachingState(
            currentHR: hr == Int.max ? 0 : hr,
            hrSmooth: hr == Int.max ? 0 : hr,
            currentZone: hr == Int.max ? 0 : ZoneCalculator.zone(for: hr, in: zones),
            targetZone: representativeZone(for: phase),
            phase: mapPhaseType(phase.kind),
            phaseTimeRemaining: TimeInterval((phase.durationSec ?? 0) - elapsedInPhaseSec),
            elapsedTime: TimeInterval(totalElapsedSec),
            coachingMessage: cue,
            isGracePeriodActive: false)
        onStateUpdate?(state)
        watchBridge.sendCoachingState(state)
    }
}
