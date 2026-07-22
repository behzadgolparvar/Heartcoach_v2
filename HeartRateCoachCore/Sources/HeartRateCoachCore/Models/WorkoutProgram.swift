import Foundation

/// A single timed segment within a workout program.
public struct WorkoutPhase: Sendable {
    /// Position in the phase sequence (0-based).
    public let index: Int
    /// Duration of this phase in seconds.
    public let duration: TimeInterval
    /// Target HR zone (1–5). nil for recovery phases — no zone enforcement.
    public let targetZone: Int?
    /// Segment type — warmup, exercise, recovery, or cooldown.
    public let type: PhaseType
    /// True for HIIT and Fartlek exercise phases — suppresses coaching for first 10 seconds.
    public let hasGracePeriod: Bool
    /// Fixed coaching instruction for this phase (e.g. "Walk it out"). nil for zone-coached phases.
    public let instruction: String?

    public init(index: Int, duration: TimeInterval, targetZone: Int?, type: PhaseType,
                hasGracePeriod: Bool, instruction: String? = nil) {
        self.index = index
        self.duration = duration
        self.targetZone = targetZone
        self.type = type
        self.hasGracePeriod = hasGracePeriod
        self.instruction = instruction
    }
}

/// The three hardcoded 35-minute workout programs.
public enum WorkoutProgram: Sendable {
    case continuous
    case hiit
    case fartlek

    /// Complete ordered phase sequence for this program. Total duration = 2100 seconds (35 min).
    public var phases: [WorkoutPhase] {
        switch self {
        case .continuous: return WorkoutProgram.continuousPhases
        case .hiit:       return WorkoutProgram.hiitPhases
        case .fartlek:    return WorkoutProgram.fartlekPhases
        }
    }

    // MARK: - Continuous (5-cycle steady progressive effort)

    private static let continuousPhases: [WorkoutPhase] = {
        let cycleZones = [2, 3, 3, 3, 4]
        var phases: [WorkoutPhase] = [
            WorkoutPhase(index: 0, duration: 120, targetZone: 1, type: .warmup, hasGracePeriod: false),
            WorkoutPhase(index: 1, duration: 180, targetZone: 2, type: .warmup, hasGracePeriod: false)
        ]
        for (i, zone) in cycleZones.enumerated() {
            let base = 2 + i * 2
            phases.append(WorkoutPhase(index: base,     duration: 300, targetZone: zone, type: .exercise, hasGracePeriod: false))
            phases.append(WorkoutPhase(index: base + 1, duration: 60,  targetZone: nil,  type: .recovery,  hasGracePeriod: false, instruction: "Walk it out"))
        }
        return phases
    }()

    // MARK: - HIIT (15 high-intensity cycles)

    private static let hiitPhases: [WorkoutPhase] = {
        // Cycles 1–3 → Zone 3, 4–12 → Zone 4, 13–15 → Zone 5
        let cycleZones = [3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5]
        var phases: [WorkoutPhase] = [
            WorkoutPhase(index: 0, duration: 120, targetZone: 1, type: .warmup, hasGracePeriod: false),
            WorkoutPhase(index: 1, duration: 180, targetZone: 2, type: .warmup, hasGracePeriod: false)
        ]
        for (i, zone) in cycleZones.enumerated() {
            let base = 2 + i * 2
            phases.append(WorkoutPhase(index: base,     duration: 60, targetZone: zone, type: .exercise, hasGracePeriod: true))
            phases.append(WorkoutPhase(index: base + 1, duration: 60, targetZone: nil,  type: .recovery,  hasGracePeriod: false, instruction: "Walk it out / don't stop"))
        }
        return phases
    }()

    // MARK: - Fartlek (15 varied 2-minute segments)

    private static let fartlekPhases: [WorkoutPhase] = {
        let zoneSequence = [2, 3, 2, 3, 4, 2, 3, 4, 3, 4, 3, 4, 2, 3, 5]
        var phases: [WorkoutPhase] = [
            WorkoutPhase(index: 0, duration: 120, targetZone: 1, type: .warmup, hasGracePeriod: false),
            WorkoutPhase(index: 1, duration: 180, targetZone: 2, type: .warmup, hasGracePeriod: false)
        ]
        for (i, zone) in zoneSequence.enumerated() {
            phases.append(WorkoutPhase(index: 2 + i, duration: 120, targetZone: zone, type: .exercise, hasGracePeriod: true))
        }
        return phases
    }()
}
