import Foundation
import Observation

@Observable
@MainActor
final class WorkoutWatchViewModel {
    var isWorkoutActive: Bool = false
    var currentHR: Int = 0
    var currentZone: Int = 0
    var phaseName: String = ""
    var lastMessage: String? = nil
}
