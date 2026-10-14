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
    private var proto: FoundationProtocol
    private var sessionFlagOverride: String?
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
    /// Timestamp of the last Watch reading we persisted — dedups forward-filled ticks.
    private var lastRecordedReadingTime: Date?
    /// A coaching cue awaiting attachment to the next real-measurement row.
    private var pendingCue: String?
    private var sessionStartDate: Date?
    private var finalScore: SessionScore?
    private var cooldownSkipped = false
    private var tickTask: Task<Void, Never>?

    private let tickInterval = 1   // 1s loop: timer/UI/safety/per-second HR; coaching still every 15s
    private let watchSendIntervalSec = 5   // throttle Watch coaching-state sends (don't flood WCSession)
    private var lastWatchSendSec = -100
    private var lastWatchZone = -1
    private var lastWatchPhase: PhaseType?

    // Sensor-dropout tracking (§J, BR-2-24).
    private var noSignalSec = 0
    private var dropoutActive = false

    // MARK: - Callbacks
    var onStateUpdate: ((CoachingState) -> Void)?
    var onWorkoutComplete: (() -> Void)?      // fires after cooldown finishes
    var onAwaitingCooldownStart: (() -> Void)?
    var onCooldownStep: ((String) -> Void)?
    /// Fires with true when HR has been absent ≥20s, false when it returns.
    var onSensorDropout: ((Bool) -> Void)?
    /// Fires (with the offending HR) when HR exceeds HRmax — drives the full-screen
    /// safety-stop overlay (§J). Fires each tick it stays above; the VM latches it.
    var onSafetyStop: ((Int) -> Void)?

    /// Tracks exercise-phase cues already spoken (intro / switch-legs).
    private var exerciseIntroDone = Set<Int>()
    private var exerciseSwitchDone = Set<Int>()

    /// Shape-HIIT runs are 50s with 2 checks (~15s/40s) instead of the 15s cycle (BR-5-12).
    private let shapeHIITCadence: Bool

    init(type: WorkoutType, zones: HRZones, restingHR: Int, maxHR: Int,
         voiceFeedback: VoiceFeedbackServiceProtocol, watchBridge: WatchBridgeProtocol,
         protocolOverride: FoundationProtocol? = nil, shapeHIITCadence: Bool = false) {
        self.shapeHIITCadence = shapeHIITCadence
        self.type = type
        self.zones = zones
        self.restingHR = restingHR
        self.maxHR = maxHR
        self.voiceFeedback = voiceFeedback
        self.watchBridge = watchBridge
        // Level Up passes a prebuilt protocol (with exercises); Foundation builds its own.
        self.proto = protocolOverride ?? FoundationProtocolBuilder.build(type: type)
        self.escalationThresholdSec = CoachingEngineV2.escalationThreshold(for: type)
        self.coaching = CoachingSessionState(seed: UInt64(Date().timeIntervalSince1970))
    }

    // MARK: - Lifecycle
    var hasReceivedHR: Bool { lastHRReceived != nil }
    /// The protocol currently driving the session (post walk-fallback switch).
    var activeProtocol: FoundationProtocol { proto }

    /// §J elevated starting HR: if the first reading is well above a calm baseline,
    /// swap the session for the walk_fallback protocol (gentle walk, excluded from
    /// progression). Call once after the first HR arrives, before coaching begins.
    /// Returns true if it switched.
    func switchToWalkFallbackIfElevated() -> Bool {
        guard let reading = lastHRReceived,
              SafetyPolicy.isElevatedStartHR(hr: reading.value, restingHR: restingHR, maxHR: maxHR)
        else { return false }
        proto = FoundationProtocolBuilder.walkFallback()
        sessionFlagOverride = "walk_fallback"
        phaseIndex = 0
        elapsedInPhaseSec = 0
        return true
    }

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
        lastRecordedReadingTime = nil
        pendingCue = nil
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
                try? await Task.sleep(nanoseconds: 1_000_000_000)
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

        // Sensor dropout (§J): no reading for ≥20s → surface a warning (safety
        // temporarily unavailable); clear when HR returns. Data gap is implicit
        // (no record is appended while hr == Int.max).
        if hr == Int.max {
            noSignalSec += tickInterval
            if noSignalSec >= SafetyPolicy.sensorDropoutSec, !dropoutActive {
                dropoutActive = true
                onSensorDropout?(true)
            }
        } else {
            noSignalSec = 0
            if dropoutActive { dropoutActive = false; onSensorDropout?(false) }
        }

        // Safety (every tick): HR above HRmax.
        if hr != Int.max, hr > maxHR {
            voiceFeedback.speak(.criticalSlowDown)
            watchBridge.sendHaptic(.long)
            onSafetyStop?(hr)
        }

        var cueText: String?

        // Exercise phase (Level Up): scripted intro + "switch legs" cue (BR-4-12).
        // Note: a literal per-rep synced voice count is deferred to Build & Test;
        // here we announce the exercise, rep target, and the mid-phase switch.
        if phase.kind == .exercise {
            let legMode = phase.exercise?.mode
            let reps = phase.exerciseReps ?? legMode?.reps ?? 0
            let perLeg = (legMode?.perLeg ?? false) && reps == (legMode?.reps ?? -1)
            if elapsedInPhaseSec == 0, !exerciseIntroDone.contains(phase.index) {
                exerciseIntroDone.insert(phase.index)
                let text = "\(phase.label) — \(reps) reps\(perLeg ? " per leg" : ""). Go!"
                cueText = text
                voiceFeedback.speak(CoachingMessage(layer: 3, text: text))
            } else if perLeg, let dur = phase.durationSec, elapsedInPhaseSec >= dur / 2,
                      !exerciseSwitchDone.contains(phase.index) {
                exerciseSwitchDone.insert(phase.index)
                cueText = "Switch legs."
                voiceFeedback.speak(CoachingMessage(layer: 3, text: "Switch legs."))
            }
        }

        // Shape-HIIT run phases: 2 checks at ~15s/40s; everything else: every 15s (BR-5-12).
        let isShapeHIITRun = shapeHIITCadence && phase.kind == .work
        let coachingDue = isShapeHIITRun
            ? (elapsedInPhaseSec == 15 || elapsedInPhaseSec == 40)
            : (elapsedInPhaseSec % 15 == 0)
        if phase.isHRCoached, let target = phase.target, coachingDue, hr != Int.max {
            let bpm = target.bpmRange(restingHR: restingHR, maxHR: maxHR)
            let tick = CoachingEngineV2.Tick(
                hr: hr, phase: phase, bpmTarget: bpm,
                phaseElapsedSec: elapsedInPhaseSec, phaseDurationSec: phase.durationSec,
                isPhaseStart: elapsedInPhaseSec == 0, itemsLeft: remainingScoredPhases(),
                escalationThresholdSec: escalationThresholdSec, sessionSec: totalElapsedSec,
                secondsPerTick: isShapeHIITRun ? 25 : 15)
            if let cue = CoachingEngineV2.tick(tick, state: &coaching) {
                cueText = cue.text
                voiceFeedback.speak(CoachingMessage(layer: 2, text: cue.text, hapticPattern: cue.haptic))
                if let h = cue.haptic { watchBridge.sendHaptic(h) }
            }
        }

        // A cue fired this tick → carry it to the next real-measurement row so its
        // phrase_type/phrase_time is preserved without inventing an HR point.
        if let c = cueText { pendingCue = c }

        if hr != Int.max {
            let zone = ZoneCalculator.zone(for: hr, in: zones)
            // Scoring samples every scored tick (forward-filled) — correct time-weighting
            // for % time in target / time-in-zones.
            if phase.kind.isScored { scoredSamples.append(HRSample(phaseIndex: phaseIndex, hr: hr)) }
            // Persist only *genuine* Watch measurements (dedup by the reading's timestamp),
            // so the saved hr_stream carries real timestamps, not forward-filled repeats.
            if let reading = lastHRReceived, reading.timestamp != lastRecordedReadingTime {
                lastRecordedReadingTime = reading.timestamp
                hrRecords.append(HRRecord(
                    timestamp: reading.timestamp, second: totalElapsedSec, hr: hr, currentZone: zone,
                    targetZone: representativeZone(for: phase), phase: mapPhaseType(phase.kind),
                    phaseKind: phase.kind, coachingMessage: pendingCue))
                pendingCue = nil
            }
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
            trainingDurationSec: trainingElapsedSec, sessionFlag: sessionFlagOverride ?? type.rawValue,
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
        case .exercise: return .exercise
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
        // Local UI updates every second (smooth timer).
        onStateUpdate?(state)
        // Throttle Watch sends: every ~5s, on zone/phase change, or when a cue fires.
        let zoneChanged = state.currentZone != lastWatchZone
        let phaseChanged = state.phase != lastWatchPhase
        if cue != nil || zoneChanged || phaseChanged
            || totalElapsedSec - lastWatchSendSec >= watchSendIntervalSec {
            watchBridge.sendCoachingState(state)
            lastWatchSendSec = totalElapsedSec
            lastWatchZone = state.currentZone
            lastWatchPhase = state.phase
        }
    }
}
