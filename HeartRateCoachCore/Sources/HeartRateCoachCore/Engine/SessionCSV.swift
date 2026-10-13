import Foundation

/// Flattens a `Session` to CSV for research export (FR-8, Q6). Pure.
/// One row per recorded second; tolerant of gaps (absent seconds simply missing).
public enum SessionCSV {

    public static func rows(for session: Session) -> String {
        var lines: [String] = []
        // Summary header (commented) + column header.
        lines.append("# session_id,\(session.id)")
        lines.append("# date,\(ISO8601DateFormatter().string(from: session.date))")
        lines.append("# type,\(session.programType.rawValue)")
        lines.append("# session_flag,\(session.sessionFlag ?? session.programType.rawValue)")
        lines.append("# score_percent,\(session.scorePercent.map { String(format: "%.1f", $0) } ?? "")")
        lines.append("# score_tier,\(session.scoreTier?.rawValue ?? "")")
        lines.append("# training_sec,\(session.trainingDurationSec ?? session.durationSec)")
        lines.append("# total_sec,\(session.durationSec)")
        lines.append("time_sec,timestamp,hr,current_zone,phase,target_zone,phrase_type,phrase_time")

        let iso = ISO8601DateFormatter()
        for r in session.hrStream {
            let phase = r.phaseKind?.rawValue ?? r.phase.rawValue
            let target = r.targetZone.map(String.init) ?? ""
            let phraseType = r.coachingMessage == nil ? "" : "cue"
            let phraseTime = r.coachingMessage == nil ? "" : String(r.second)
            let ts = iso.string(from: r.timestamp)   // real measurement time (ISO-8601 UTC)
            lines.append("\(r.second),\(ts),\(r.hr),\(r.currentZone),\(phase),\(target),\(phraseType),\(phraseTime)")
        }
        return lines.joined(separator: "\n")
    }
}
