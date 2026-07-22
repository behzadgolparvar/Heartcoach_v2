import Foundation

/// Pure stateless coaching logic.
/// All state lives in CoachingEngineState (owned by WorkoutSessionManager).
/// tick() is a static function — same inputs always produce the same output.
public enum CoachingEngine {

    // MARK: - Public Interface

    /// Evaluates one 5-second coaching tick.
    ///
    /// - Parameters:
    ///   - hr: Raw HR reading from Watch sensor in bpm. Pass Int.max if signal is stale (≥15s).
    ///   - phase: Currently active workout phase.
    ///   - elapsedInPhase: Seconds elapsed in the current phase (for grace period check).
    ///   - state: All mutable coaching state — mutated in place.
    ///   - zones: Personalised HR zones for this user.
    ///   - now: Current time — injected for determinism in tests. Defaults to Date().
    /// - Returns: The coaching message to speak (and optionally send as haptic), or nil for a silent tick.
    public static func tick(
        hr: Int,
        phase: WorkoutPhase,
        elapsedInPhase: TimeInterval,
        state: inout CoachingEngineState,
        zones: HRZones,
        now: Date = Date()
    ) -> CoachingMessage? {

        // Always update the HR buffer first (even on staleness — WorkoutSessionManager
        // passes Int.max for stale signal, which triggers Layer 1 before reaching smoothing).
        if hr != Int.max {
            updateBuffer(hr: hr, state: &state)
        }

        let smooth = (hr == Int.max) ? Int.max : state.hrSmooth

        // Layer 1 — Safety (evaluated first; early return if fires)
        if let safetyMessage = evaluateLayer1(hrSmooth: smooth, zones: zones, state: &state) {
            return safetyMessage
        }

        // Layer 2 — Zone Coaching (only if Layer 1 did not fire)
        if let zoneMessage = evaluateLayer2(
            hrSmooth: smooth,
            phase: phase,
            elapsedInPhase: elapsedInPhase,
            state: &state,
            zones: zones,
            now: now
        ) {
            return zoneMessage
        }

        // Layer 3 — Positive Feedback (only if Layers 1 and 2 both silent)
        return evaluateLayer3(hrSmooth: smooth, phase: phase, state: &state, zones: zones)
    }

    // MARK: - Private Helpers

    private static func updateBuffer(hr: Int, state: inout CoachingEngineState) {
        state.hrBuffer.append(hr)
        if state.hrBuffer.count > 2 { state.hrBuffer.removeFirst() }
    }

    private static func evaluateLayer1(
        hrSmooth: Int,
        zones: HRZones,
        state: inout CoachingEngineState
    ) -> CoachingMessage? {
        // Stale signal — no HR for ≥15 seconds
        if hrSmooth == Int.max {
            state.consecutiveInZoneSeconds = 0
            return .noSignal
        }

        // HR above HRmax — emergency stop
        if hrSmooth > zones.zone5.max {
            state.consecutiveInZoneSeconds = 0
            return .emergencyStop
        }

        // HR within 5% of zone5.max — critical warning
        let criticalThreshold = Int(Double(zones.zone5.max) * 0.95)
        if hrSmooth >= criticalThreshold {
            state.consecutiveInZoneSeconds = 0
            return .criticalSlowDown
        }

        return nil
    }

    private static func evaluateLayer2(
        hrSmooth: Int,
        phase: WorkoutPhase,
        elapsedInPhase: TimeInterval,
        state: inout CoachingEngineState,
        zones: HRZones,
        now: Date
    ) -> CoachingMessage? {
        // Recovery phases have no target zone — coaching not applicable
        guard let targetZone = phase.targetZone else {
            state.consecutiveInZoneSeconds = 0
            return nil
        }

        // Grace period — suppress coaching for first 10 seconds of HIIT/Fartlek phases
        guard elapsedInPhase >= 10.0 else { return nil }

        // Anti-spam — minimum 20 seconds between Layer 2 messages
        if let lastAt = state.lastLayer2MessageAt,
           now.timeIntervalSince(lastAt) < 20 {
            // Still update in-zone counter even when suppressed
            updateInZoneCounter(hrSmooth: hrSmooth, targetZone: targetZone, state: &state, zones: zones)
            return nil
        }

        guard let zone = zones.zone(number: targetZone) else { return nil }

        // Determine coaching direction
        let message: CoachingMessage
        if hrSmooth < zone.min {
            message = .speedUp
        } else if hrSmooth > zone.max {
            message = .slowDown
        } else {
            // In-zone — update counter but no Layer 2 message
            updateInZoneCounter(hrSmooth: hrSmooth, targetZone: targetZone, state: &state, zones: zones)
            return nil
        }

        state.lastLayer2MessageAt = now
        state.consecutiveInZoneSeconds = 0
        return message
    }

    private static func evaluateLayer3(
        hrSmooth: Int,
        phase: WorkoutPhase,
        state: inout CoachingEngineState,
        zones: HRZones
    ) -> CoachingMessage? {
        guard let targetZone = phase.targetZone,
              let zone = zones.zone(number: targetZone) else {
            return nil
        }

        let isInZone = hrSmooth >= zone.min && hrSmooth <= zone.max
        if isInZone {
            state.consecutiveInZoneSeconds += 5
            if state.consecutiveInZoneSeconds >= 30 {
                state.consecutiveInZoneSeconds = 0  // reset so it doesn't fire every tick
                return .keepItUp
            }
        } else {
            state.consecutiveInZoneSeconds = 0
        }

        return nil
    }

    private static func updateInZoneCounter(
        hrSmooth: Int,
        targetZone: Int,
        state: inout CoachingEngineState,
        zones: HRZones
    ) {
        guard let zone = zones.zone(number: targetZone) else { return }
        if hrSmooth >= zone.min && hrSmooth <= zone.max {
            state.consecutiveInZoneSeconds += 5
        } else {
            state.consecutiveInZoneSeconds = 0
        }
    }
}
