import Foundation

/// The §B ratio-progression tables (HIIT:Continuous per sub-phase), keyed by
/// track × mentality lean. Sub-phase index is 0–2. Immutable spec data.
/// `beginnerRoutineCardio` has no ratio (handled specially — BR-3-4, Q3=A).
public enum ProgressionTables {

    /// Ratio for a ratio-based track at a sub-phase (0–2). nil for Routine/Cardio.
    public static func ratio(track: ProgressionTrack,
                             lean: MentalityLean,
                             subPhase: Int) -> SessionRatio? {
        let sp = max(0, min(2, subPhase))
        guard let rows = table(track)?[lean] else { return nil }
        return rows[sp]
    }

    private static func table(_ track: ProgressionTrack) -> [MentalityLean: [SessionRatio]]? {
        switch track {
        case .beginnerFastWeightLoss:
            return [
                .outcome: [SessionRatio(1, 2), SessionRatio(1, 1), SessionRatio(2, 1)],
                .mixed:   [SessionRatio(1, 3), SessionRatio(1, 2), SessionRatio(1, 1)],
                .process: [SessionRatio(1, 4), SessionRatio(1, 3), SessionRatio(1, 2)],
            ]
        case .intermediate:
            return [
                .outcome: [SessionRatio(1, 1), SessionRatio(2, 1), SessionRatio(3, 1)],
                .mixed:   [SessionRatio(1, 2), SessionRatio(1, 1), SessionRatio(2, 1)],
                .process: [SessionRatio(1, 3), SessionRatio(1, 2), SessionRatio(1, 1)],
            ]
        case .advanced:
            return [
                .outcome: [SessionRatio(2, 1), SessionRatio(3, 1), SessionRatio(4, 1)],
                .mixed:   [SessionRatio(1, 1), SessionRatio(2, 1), SessionRatio(3, 1)],
                .process: [SessionRatio(1, 2), SessionRatio(1, 1), SessionRatio(2, 1)],
            ]
        case .beginnerRoutineCardio:
            return nil   // Continuous-only + 1-in-4 HIIT for outcome (BR-3-4)
        }
    }
}
