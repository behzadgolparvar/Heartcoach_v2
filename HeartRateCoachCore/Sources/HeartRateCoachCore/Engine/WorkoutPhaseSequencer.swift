import Foundation

/// Events emitted by the sequencer as time advances.
public enum SequencerEvent: Sendable {
    /// No phase boundary was crossed.
    case none
    /// The sequencer advanced into a new phase.
    case phaseTransition(WorkoutPhase)
    /// All training phases have elapsed. Cool-down is optional and user-triggered.
    case mainWorkoutComplete
}

/// Iterates through a WorkoutProgram's phase sequence as time elapses.
///
/// Mutating — advance(by:) updates internal state. All other properties are read-only.
/// Grace period suppresses Layer 2 coaching for the first 10 seconds of HIIT/Fartlek phases.
public struct WorkoutPhaseSequencer: Sendable {

    // MARK: - Private State

    private let phases: [WorkoutPhase]
    private var currentPhaseIndex: Int = 0
    private var elapsedInPhase: TimeInterval = 0
    private var totalElapsed: TimeInterval = 0

    // MARK: - Initialisation

    /// Creates a sequencer for the given workout program, positioned at the first phase.
    public init(program: WorkoutProgram) {
        self.phases = program.phases
    }

    // MARK: - Read-only Properties

    /// The currently active phase.
    public var currentPhase: WorkoutPhase {
        phases[currentPhaseIndex]
    }

    /// Seconds remaining in the current phase.
    public var timeRemainingInPhase: TimeInterval {
        currentPhase.duration - elapsedInPhase
    }

    /// Total elapsed workout time in seconds.
    public var totalElapsedTime: TimeInterval {
        totalElapsed
    }

    /// True if the grace period is currently suppressing coaching feedback.
    /// Active only during the first 10 seconds of a phase that has hasGracePeriod = true.
    public var isGracePeriodActive: Bool {
        guard !isComplete else { return false }
        return currentPhase.hasGracePeriod && elapsedInPhase < 10.0
    }

    /// True after the final training phase has elapsed.
    public var isComplete: Bool {
        currentPhaseIndex >= phases.count
    }

    // MARK: - Mutation

    /// Advances the sequencer by the given time interval.
    ///
    /// Handles multiple phase transitions in a single call (e.g. if delta > phase duration).
    /// - Returns: The most significant event that occurred during this advance:
    ///   `.mainWorkoutComplete`, `.phaseTransition`, or `.none`.
    @discardableResult
    public mutating func advance(by seconds: TimeInterval) -> SequencerEvent {
        guard !isComplete else { return .none }

        elapsedInPhase += seconds
        totalElapsed += seconds

        var event: SequencerEvent = .none

        while !isComplete && elapsedInPhase >= phases[currentPhaseIndex].duration {
            elapsedInPhase -= phases[currentPhaseIndex].duration
            currentPhaseIndex += 1

            if currentPhaseIndex >= phases.count {
                return .mainWorkoutComplete
            }

            event = .phaseTransition(phases[currentPhaseIndex])
        }

        return event
    }
}
