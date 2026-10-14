import Foundation
import Observation

@Observable
@MainActor
final class WorkoutWatchViewModel {
    var isWorkoutActive: Bool = false
    var currentHR: Int = 0
    var currentZone: Int = 0
    /// Target zone for the current phase (0 = none / recovery).
    var targetZone: Int = 0
    var phaseName: String = ""
    /// Seconds left in the current phase (for the header countdown).
    var phaseRemainingSec: Int = 0
    var lastMessage: String? = nil
}
