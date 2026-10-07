import Foundation

/// The mandatory 2-minute cooldown stretch sequence (spec §F), identical across
/// all stages and workout types. Six standing stretches, 120s total.
public enum CooldownStep: String, Codable, Sendable, CaseIterable {
    case quad, hamstring, calf, overheadReach, adductor, frogSit

    public var durationSec: Int {
        switch self {
        case .quad: return 30          // 15s each leg
        case .calf: return 30          // 15s each leg
        case .hamstring, .overheadReach, .adductor, .frogSit: return 15
        }
    }

    public var label: String {
        switch self {
        case .quad: return "Quad stretch"
        case .hamstring: return "Hamstring stretch"
        case .calf: return "Calf stretch"
        case .overheadReach: return "Overhead reach"
        case .adductor: return "Adductor stretch"
        case .frogSit: return "Frog sit"
        }
    }

    public var voiceCue: String {
        switch self {
        case .quad: return "Quad stretch — fifteen seconds each leg."
        case .hamstring: return "Hamstring stretch — bend and reach."
        case .calf: return "Calf stretch — fifteen seconds each leg."
        case .overheadReach: return "Overhead reach — straight arms up."
        case .adductor: return "Adductor stretch — open up, bend and reach."
        case .frogSit: return "Frog sit — hold and breathe."
        }
    }

    /// Total cooldown duration (120s).
    public static var totalDurationSec: Int {
        allCases.reduce(0) { $0 + $1.durationSec }
    }
}
