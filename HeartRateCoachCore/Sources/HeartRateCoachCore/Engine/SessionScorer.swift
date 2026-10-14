import Foundation

/// One per-second heart-rate sample tagged with the phase it occurred in.
public struct HRSample: Sendable, Equatable {
    public let phaseIndex: Int
    public let hr: Int
    public init(phaseIndex: Int, hr: Int) {
        self.phaseIndex = phaseIndex
        self.hr = hr
    }
}

/// Computes a `SessionScore` from the per-second stream (spec §D/FR-6).
/// Only scored phases (`warmup/block/work`) contribute; rest/buffer/transition/
/// cooldown are excluded from both numerator and denominator (BR-2-12/13).
public enum SessionScorer {

    public static func score(protocol proto: FoundationProtocol,
                             samples: [HRSample],
                             restingHR: Int,
                             maxHR: Int,
                             zones: HRZones) -> SessionScore {
        var inRange = 0
        var scoredTotal = 0
        var zoneSec: [Int: Int] = [:]

        for sample in samples {
            guard sample.phaseIndex >= 0, sample.phaseIndex < proto.phases.count else { continue }
            let phase = proto.phases[sample.phaseIndex]
            guard phase.kind.isScored, let target = phase.target else { continue }

            scoredTotal += 1
            let bpm = target.bpmRange(restingHR: restingHR, maxHR: maxHR)
            if bpm.contains(sample.hr) { inRange += 1 }
            if let z = zoneNumber(for: sample.hr, zones: zones) {
                zoneSec[z, default: 0] += 1
            }
        }

        let percent = scoredTotal == 0 ? 0 : Double(inRange) / Double(scoredTotal) * 100
        return SessionScore(percentInTarget: percent,
                            tier: ScoreTier.from(percent: percent),
                            timeInZoneSec: zoneSec)
    }

    /// Lower zone wins at an exact boundary; clamps below zone 1 / above zone 5.
    private static func zoneNumber(for hr: Int, zones: HRZones) -> Int? {
        for n in 1...5 {
            if let z = zones.zone(number: n), hr >= z.min, hr <= z.max { return n }
        }
        if hr < zones.zone1.min { return 1 }
        if hr > zones.zone5.max { return 5 }
        return nil
    }
}
