import Foundation

/// The user's position in the v5 program: the current training stage plus
/// per-stage progression history. Classification (Beginner/Intermediate/Advanced)
/// is stored on the profile, not here, and carries forward unchanged (BR-1b-6).
public struct ProgramState: Codable, Sendable, Equatable {
    public var currentStage: TrainingStage
    /// Progress per stage. Preserves history as the user advances.
    public var stageProgress: [TrainingStage: StageProgress]

    public init(currentStage: TrainingStage, stageProgress: [TrainingStage: StageProgress]) {
        self.currentStage = currentStage
        self.stageProgress = stageProgress
    }

    /// BR-1b-7 — every new user starts at Foundation, session 0, regardless of tier.
    public static func newUser() -> ProgramState {
        ProgramState(
            currentStage: .foundation,
            stageProgress: [.foundation: StageProgress(stage: .foundation)]
        )
    }

    /// Progress for the current stage (creating a zeroed record if absent).
    public var currentProgress: StageProgress {
        stageProgress[currentStage] ?? StageProgress(stage: currentStage)
    }
}

// MARK: - Codable (TrainingStage keys)

extension ProgramState {
    private enum CodingKeys: String, CodingKey {
        case currentStage, stageProgress
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentStage = try c.decode(TrainingStage.self, forKey: .currentStage)
        // Dictionary<TrainingStage, _> encodes as an array of alternating
        // key/value pairs under the synthesized Codable; decode via an
        // intermediate [String: StageProgress] so the stored shape is a plain
        // object keyed by the stage raw value (stable Firestore JSON).
        let raw = try c.decode([String: StageProgress].self, forKey: .stageProgress)
        var map: [TrainingStage: StageProgress] = [:]
        for (key, value) in raw {
            if let stage = TrainingStage(rawValue: key) { map[stage] = value }
        }
        stageProgress = map
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currentStage, forKey: .currentStage)
        var raw: [String: StageProgress] = [:]
        for (stage, value) in stageProgress { raw[stage.rawValue] = value }
        try c.encode(raw, forKey: .stageProgress)
    }
}
