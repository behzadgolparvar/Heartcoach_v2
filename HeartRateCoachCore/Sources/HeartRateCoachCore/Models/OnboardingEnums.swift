import Foundation

// MARK: - Demographics

public enum Gender: String, Codable, Sendable, CaseIterable {
    case male, female, preferNotToSay

    public var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

public enum FitnessExperience: String, Codable, Sendable, CaseIterable {
    case beginner, intermediate, advanced

    public var displayName: String { rawValue.capitalized }
}

public enum UnitsPreference: String, Codable, Sendable {
    case metric, imperial
}

// MARK: - Goals (v2 — multi-select)

/// v2 training goals (multi-select). v1 `Goal` (fatBurn/endurance) is retained separately
/// for the legacy workout engine until it is retired.
public enum TrainingGoal: String, Codable, Sendable, CaseIterable {
    case fastWeightLoss = "fast_weight_loss"
    case routine
    case cardioFitness = "cardio_fitness"

    public var displayName: String {
        switch self {
        case .fastWeightLoss: return "Fast weight loss"
        case .routine: return "Exercise as routine"
        case .cardioFitness: return "Cardiovascular fitness"
        }
    }
}

// MARK: - Scheduling

public enum TimeOfDay: String, Codable, Sendable, CaseIterable {
    case morning, afternoon, evening
    public var displayName: String { rawValue.capitalized }
}

public enum ReminderMethod: String, Codable, Sendable, CaseIterable {
    case call, text
    public var displayName: String { rawValue.capitalized }
}

public enum Weekday: String, Codable, Sendable, CaseIterable {
    case mon, tue, wed, thu, fri, sat, sun
    public var displayName: String {
        switch self {
        case .mon: return "Mon"; case .tue: return "Tue"; case .wed: return "Wed"
        case .thu: return "Thu"; case .fri: return "Fri"; case .sat: return "Sat"; case .sun: return "Sun"
        }
    }
}

// MARK: - Facility / Device

public enum Equipment: String, Codable, Sendable, CaseIterable {
    case biking, elliptical, treadmill, outdoorRunning = "outdoor_running", other
    public var displayName: String {
        switch self {
        case .biking: return "Biking"; case .elliptical: return "Elliptical"
        case .treadmill: return "Treadmill"; case .outdoorRunning: return "Outdoor running"
        case .other: return "Other"
        }
    }
}

public enum LocationPreference: String, Codable, Sendable, CaseIterable {
    case indoor, outdoor, noPreference = "no_preference"
    public var displayName: String {
        switch self {
        case .indoor: return "Indoor"; case .outdoor: return "Outdoor"; case .noPreference: return "No preference"
        }
    }
}

public enum Wearable: String, Codable, Sendable, CaseIterable {
    case appleWatch = "apple_watch", none
    public var displayName: String { self == .appleWatch ? "Apple Watch" : "None" }
}

public enum TrackingApp: String, Codable, Sendable, CaseIterable {
    case strava, other, none
    public var displayName: String { self == .strava ? "Strava" : rawValue.capitalized }
}
