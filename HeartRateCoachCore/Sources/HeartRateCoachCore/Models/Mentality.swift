import Foundation

// MARK: - Mentality (3 binary questions + derived lean)

public enum MotivationDriver: String, Codable, Sendable {
    case process   // "I enjoy the process / workout itself"
    case outcome   // "I care most about seeing results"
}

public enum MissedResponse: String, Codable, Sendable {
    case habit     // "I feel like I broke a habit"
    case goal      // "I feel like I'm losing progress"
}

public enum RoutinePreference: String, Codable, Sendable {
    case fixed     // "I prefer a fixed routine"
    case variety   // "I prefer variety"
}

/// Overall lean consumed by the assignment engine (spec §2.3).
public enum MentalityLean: String, Codable, Sendable {
    case process, outcome, mixed
}

public struct Mentality: Codable, Sendable, Equatable {
    public let motivationDriver: MotivationDriver
    public let missedResponse: MissedResponse
    public let routinePreference: RoutinePreference

    public init(motivationDriver: MotivationDriver,
                missedResponse: MissedResponse,
                routinePreference: RoutinePreference) {
        self.motivationDriver = motivationDriver
        self.missedResponse = missedResponse
        self.routinePreference = routinePreference
    }

    /// Derived lean via majority rule (BR-7):
    /// outcome-ish = outcome / goal / variety; process-ish = process / habit / fixed.
    /// 3–0 → strong lean; 2–1 → mixed.
    public var derivedLean: MentalityLean {
        var outcomeCount = 0
        if motivationDriver == .outcome { outcomeCount += 1 }
        if missedResponse == .goal { outcomeCount += 1 }
        if routinePreference == .variety { outcomeCount += 1 }
        switch outcomeCount {
        case 3: return .outcome
        case 0: return .process
        default: return .mixed   // 1 or 2 → mixed
        }
    }
}
