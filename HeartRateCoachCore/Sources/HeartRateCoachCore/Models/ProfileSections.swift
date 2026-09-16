import Foundation

// MARK: - Health history (optional section — stored, mostly future-use)

public enum ChronicCondition: String, Codable, Sendable, CaseIterable {
    case t2dm, cvd, hypertension, none
    public var displayName: String {
        switch self {
        case .t2dm: return "Type 2 Diabetes"; case .cvd: return "Cardiovascular Disease"
        case .hypertension: return "Hypertension"; case .none: return "None"
        }
    }
}

public enum HRMedication: String, Codable, Sendable, CaseIterable {
    case betaBlockers = "beta_blockers", other, none
    public var displayName: String {
        switch self {
        case .betaBlockers: return "Beta-blockers"; case .other: return "Other"; case .none: return "None"
        }
    }
}

public enum SmokingStatus: String, Codable, Sendable, CaseIterable {
    case never, former, current
    public var displayName: String { rawValue.capitalized }
}

public enum JointIssue: String, Codable, Sendable, CaseIterable {
    case knees, back, hips, ankles, none
    public var displayName: String { rawValue.capitalized }
}

public enum OccupationActivity: String, Codable, Sendable, CaseIterable {
    case sedentary, light, active, veryActive = "very_active"
    public var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"; case .light: return "Lightly active"
        case .active: return "Active"; case .veryActive: return "Very active"
        }
    }
}

public struct HealthHistory: Codable, Sendable, Equatable {
    public var chronicConditions: Set<ChronicCondition>
    public var chronicConditionsOther: String?
    public var hrMedications: Set<HRMedication>
    public var onAntiObesityTherapy: Bool
    public var smokingStatus: SmokingStatus?
    public var jointIssues: Set<JointIssue>
    public var jointIssuesOther: String?
    public var occupationActivity: OccupationActivity?

    public init(chronicConditions: Set<ChronicCondition> = [], chronicConditionsOther: String? = nil,
                hrMedications: Set<HRMedication> = [], onAntiObesityTherapy: Bool = false,
                smokingStatus: SmokingStatus? = nil, jointIssues: Set<JointIssue> = [],
                jointIssuesOther: String? = nil, occupationActivity: OccupationActivity? = nil) {
        self.chronicConditions = chronicConditions
        self.chronicConditionsOther = chronicConditionsOther
        self.hrMedications = hrMedications
        self.onAntiObesityTherapy = onAntiObesityTherapy
        self.smokingStatus = smokingStatus
        self.jointIssues = jointIssues
        self.jointIssuesOther = jointIssuesOther
        self.occupationActivity = occupationActivity
    }
}

// MARK: - Schedule

public struct Schedule: Codable, Sendable, Equatable {
    public var sessionLengthMin: Int
    public var frequencyPerWeek: Int
    public var preferredDays: Set<Weekday>
    public var preferredTimeOfDay: TimeOfDay?
    public var reminderMethod: ReminderMethod?

    public init(sessionLengthMin: Int, frequencyPerWeek: Int, preferredDays: Set<Weekday> = [],
                preferredTimeOfDay: TimeOfDay? = nil, reminderMethod: ReminderMethod? = nil) {
        self.sessionLengthMin = sessionLengthMin
        self.frequencyPerWeek = frequencyPerWeek
        self.preferredDays = preferredDays
        self.preferredTimeOfDay = preferredTimeOfDay
        self.reminderMethod = reminderMethod
    }
}

// MARK: - Device / tech

public struct DeviceInfo: Codable, Sendable, Equatable {
    public var wearable: Wearable
    public var trackingApps: Set<TrackingApp>

    public init(wearable: Wearable = .none, trackingApps: Set<TrackingApp> = []) {
        self.wearable = wearable
        self.trackingApps = trackingApps
    }
}

// MARK: - Facility / equipment

public struct FacilityInfo: Codable, Sendable, Equatable {
    public var equipment: Set<Equipment>
    public var equipmentOther: String?
    public var locationPreference: LocationPreference?

    public init(equipment: Set<Equipment> = [], equipmentOther: String? = nil,
                locationPreference: LocationPreference? = nil) {
        self.equipment = equipment
        self.equipmentOther = equipmentOther
        self.locationPreference = locationPreference
    }
}

// MARK: - Consent

public struct Consent: Codable, Sendable, Equatable {
    public var healthDataConsent: Bool
    public var remindersConsent: Bool
    public var consentedAt: Date?
    public var consentVersion: String

    public init(healthDataConsent: Bool = false, remindersConsent: Bool = false,
                consentedAt: Date? = nil, consentVersion: String = "1.0") {
        self.healthDataConsent = healthDataConsent
        self.remindersConsent = remindersConsent
        self.consentedAt = consentedAt
        self.consentVersion = consentVersion
    }

    public var isComplete: Bool { healthDataConsent && remindersConsent }
}
