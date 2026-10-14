import Foundation

/// CoachingEngine v2 (spec §D). Pure, layered coaching for Foundation sessions.
/// One cue per tick, chosen by the highest-priority layer that fires (BR-2-5).
/// The v1 `CoachingEngine` is left untouched (Q6=A) until the flow switches over.
///
/// Safety (HR > HRmax) is owned by the session driver on its 5s sub-check and is
/// not produced here. Health values are never logged (SECURITY-03).
public enum CoachingEngineV2 {

    /// Inputs for one coaching tick.
    public struct Tick: Sendable {
        public let hr: Int
        public let phase: FoundationPhase
        public let bpmTarget: ClosedRange<Int>?
        public let phaseElapsedSec: Int
        public let phaseDurationSec: Int?
        public let isPhaseStart: Bool
        public let itemsLeft: Int?
        public let escalationThresholdSec: Int   // 30 HIIT / 60 Continuous
        public let sessionSec: Int
        public let secondsPerTick: Int

        public init(hr: Int, phase: FoundationPhase, bpmTarget: ClosedRange<Int>?,
                    phaseElapsedSec: Int, phaseDurationSec: Int?, isPhaseStart: Bool,
                    itemsLeft: Int?, escalationThresholdSec: Int, sessionSec: Int,
                    secondsPerTick: Int = 15) {
            self.hr = hr; self.phase = phase; self.bpmTarget = bpmTarget
            self.phaseElapsedSec = phaseElapsedSec; self.phaseDurationSec = phaseDurationSec
            self.isPhaseStart = isPhaseStart; self.itemsLeft = itemsLeft
            self.escalationThresholdSec = escalationThresholdSec
            self.sessionSec = sessionSec; self.secondsPerTick = secondsPerTick
        }
    }

    public static func tick(_ t: Tick, state: inout CoachingSessionState) -> CoachingCue? {
        state.enterPhase(t.phase.index)

        // Non-coached phases: only an instruction at the very start of a rest phase.
        guard t.phase.isHRCoached, let target = t.bpmTarget else {
            if t.phase.kind == .rest, t.isPhaseStart {
                return cue(.restInstruction, .transition, &state, at: t.sessionSec)
            }
            return nil
        }

        // Deviation (BR-2-6): distance from the nearest edge; in-range = 0.
        let off = max(0, target.lowerBound - t.hr, t.hr - target.upperBound)
        let inRange = off == 0
        let low = t.hr < target.lowerBound

        // Update run counters.
        if inRange {
            state.inZoneCumSec += t.secondsPerTick
            state.offRunSec = 0
        } else {
            state.offRunSec += t.secondsPerTick
        }

        // Layer: end-of-phase (last 10s), once per phase.
        if let dur = t.phaseDurationSec, dur - t.phaseElapsedSec <= 10,
           !state.endAnnouncedPhases.contains(t.phase.index) {
            state.endAnnouncedPhases.insert(t.phase.index)
            return cue(.endOfPhase, .endOfPhase, &state, at: t.sessionSec)
        }

        // Layer: escalation (sustained off-zone ≥ threshold), rate-limited.
        if off > 0, state.offRunSec >= t.escalationThresholdSec,
           state.lastEscalationSec == nil ||
           t.sessionSec - (state.lastEscalationSec ?? 0) >= t.escalationThresholdSec {
            state.lastEscalationSec = t.sessionSec
            return cue(low ? .escalationLow : .escalationHigh, .escalation, &state,
                       at: t.sessionSec, haptic: low ? .short : .long)
        }

        // Layer: off-zone standard.
        if off > 0 {
            let major = off >= 5
            let category: PhraseCategory = major
                ? (low ? .offMajorLow : .offMajorHigh)
                : (low ? .offMinorLow : .offMinorHigh)
            return cue(category, .offZone, &state, at: t.sessionSec, haptic: low ? .short : .long)
        }

        // Layer: in-zone confirmation — at most once per block, late, if majority in-range (BR-2-8).
        if inRange, let dur = t.phaseDurationSec,
           !state.inZonePraisedPhases.contains(t.phase.index),
           state.inZoneCumSec * 2 >= dur, t.phaseElapsedSec * 5 >= dur * 4 {
            state.inZonePraisedPhases.insert(t.phase.index)
            return cue(.inZone, .inZone, &state, at: t.sessionSec, haptic: .doubleTap)
        }

        // Layer: transition — block/round start.
        if t.isPhaseStart {
            if let left = t.itemsLeft, left <= 3 {
                return cue(.roundsLeft, .transition, &state, at: t.sessionSec)
            }
            return cue(.blockStart, .transition, &state, at: t.sessionSec)
        }

        return nil
    }

    private static func cue(_ category: PhraseCategory, _ priority: CoachingPriority,
                            _ state: inout CoachingSessionState, at sec: Int,
                            haptic: HapticPattern? = nil) -> CoachingCue {
        CoachingCue(text: state.nextPhrase(category), category: category,
                    priority: priority, atSec: sec, haptic: haptic)
    }

    /// Escalation threshold by type (BR-2-7): HIIT 30s, Continuous 60s.
    public static func escalationThreshold(for type: WorkoutType) -> Int {
        type == .hiit ? 30 : 60
    }
}
