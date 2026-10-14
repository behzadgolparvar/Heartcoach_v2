import Foundation

/// The user's Shape unlock answers (§E), captured once on entering Shape.
public struct ShapeUnlock: Codable, Sendable, Equatable {
    /// §E Q1 — default daily Option (A outdoor / B weights).
    public var equipmentPreference: ShapeOption
    /// §E Q3 — focus areas; pre-fill the per-session muscle picker.
    public var focusAreas: Set<MuscleGroup>
    /// §E Q2 — acknowledged any pain during Level Up (safety check).
    public var acknowledgedLevelUpPain: Bool
    public var unlockedAt: Date

    public init(equipmentPreference: ShapeOption, focusAreas: Set<MuscleGroup>,
                acknowledgedLevelUpPain: Bool, unlockedAt: Date) {
        self.equipmentPreference = equipmentPreference
        self.focusAreas = focusAreas
        self.acknowledgedLevelUpPain = acknowledgedLevelUpPain
        self.unlockedAt = unlockedAt
    }
}
