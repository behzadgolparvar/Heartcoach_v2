import Foundation

/// A single heart rate zone boundary.
public struct Zone: Codable, Sendable {
    /// Zone number 1–5.
    public let number: Int
    /// Human-readable zone label (e.g. "Recovery", "Aerobic").
    public let name: String
    /// Lower boundary in bpm (inclusive).
    public let min: Int
    /// Upper boundary in bpm (inclusive — lower zone wins at exact boundary).
    public let max: Int

    public init(number: Int, name: String, min: Int, max: Int) {
        self.number = number
        self.name = name
        self.min = min
        self.max = max
    }
}

/// Five personalised HR zones computed via the Karvonen formula.
public struct HRZones: Codable, Sendable {
    /// Zone 1 — Recovery (50–60% HRR)
    public let zone1: Zone
    /// Zone 2 — Easy / Fat Burn (60–70% HRR)
    public let zone2: Zone
    /// Zone 3 — Aerobic (70–80% HRR)
    public let zone3: Zone
    /// Zone 4 — Threshold (80–90% HRR)
    public let zone4: Zone
    /// Zone 5 — Max Effort (90–100% HRR)
    public let zone5: Zone

    public init(zone1: Zone, zone2: Zone, zone3: Zone, zone4: Zone, zone5: Zone) {
        self.zone1 = zone1
        self.zone2 = zone2
        self.zone3 = zone3
        self.zone4 = zone4
        self.zone5 = zone5
    }

    /// Returns the zone struct for the given zone number (1–5), or nil if out of range.
    public func zone(number: Int) -> Zone? {
        switch number {
        case 1: return zone1
        case 2: return zone2
        case 3: return zone3
        case 4: return zone4
        case 5: return zone5
        default: return nil
        }
    }
}
