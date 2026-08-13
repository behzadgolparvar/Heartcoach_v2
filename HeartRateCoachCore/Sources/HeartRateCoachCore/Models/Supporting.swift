import Foundation

public enum Goal: String, Codable, Sendable {
    case fatBurn = "fat_burn"
    case endurance
}

public enum WorkoutType: String, Codable, Sendable {
    case continuous
    case hiit
    case fartlek

    /// Human-readable name for display (preserves "HIIT" casing).
    public var displayName: String {
        switch self {
        case .continuous: return "Continuous"
        case .hiit:       return "HIIT"
        case .fartlek:    return "Fartlek"
        }
    }
}

public enum Sex: String, Codable, Sendable {
    case male, female, other
}

/// The type of segment within a workout program.
public enum PhaseType: String, Codable, Sendable {
    case warmup
    case exercise
    case recovery
    case cooldown
}

public enum SyncStatus: Sendable {
    case synced
    case savedLocally
    case syncing
    case failed
}

/// Haptic pattern sent from iPhone coaching engine to Apple Watch.
/// String raw values allow direct serialization over WCSession message dictionaries.
public enum HapticPattern: String, Sendable {
    /// HR below target zone — short vibration.
    case short
    /// HR above target zone — long vibration.
    case long
    /// 30-second in-zone positive feedback — double tap.
    case doubleTap
    /// HR above HRmax emergency stop — strong repeated vibration.
    case emergencyRepeated
}
