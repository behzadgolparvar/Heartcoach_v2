import Foundation
import Observation

@Observable
@MainActor
final class WorkoutWatchViewModel {
    var isWorkoutActive: Bool = false
    /// True while the phone-driven workout is paused (drives the Pause/Resume button).
    var isPaused: Bool = false
    /// Sends a controls-page action to the phone ("pause" / "resume" / "end").
    /// Set by WatchSessionManager at activation.
    @ObservationIgnored var onControl: ((String) -> Void)?
    var currentHR: Int = 0
    var currentZone: Int = 0
    /// Target zone for the current phase (0 = none / recovery).
    var targetZone: Int = 0
    var phaseName: String = ""
    /// Seconds left in the current phase (for the header countdown).
    var phaseRemainingSec: Int = 0
    /// Seconds left until the whole session ends (for the SESSION ENDS countdown).
    var sessionRemainingSec: Int = 0
    var lastMessage: String? = nil
    /// Static HR zone bounds from the phone (10 ints: z1.min,z1.max … z5.min,z5.max).
    /// Empty until the phone sends them at workout start. Used to slide the gauge marker.
    var zoneBounds: [Int] = []
    /// Resting HR from the phone — floor of the below-Z1 block (so warmup HR spreads across it).
    var restingHR: Int = 60

    /// bpm span of the current block (below-Z1 uses restingHR…z1.min), mirroring the iPhone.
    /// Returns nil until the zone table has arrived.
    func blockDomain(_ zone: Int) -> (lo: Int, hi: Int)? {
        guard zoneBounds.count == 10 else { return nil }
        let z = min(5, max(0, zone))
        if z == 0 { return (restingHR, zoneBounds[0]) }   // below-Z1: restingHR … z1.min
        let i = (z - 1) * 2
        return (zoneBounds[i], zoneBounds[i + 1])
    }
}
