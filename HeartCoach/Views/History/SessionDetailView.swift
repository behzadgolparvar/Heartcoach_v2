import SwiftUI
import HeartRateCoachCore

struct SessionDetailView: View {
    let session: Session

    private var avgHR: Int {
        let hrs = session.hrStream.map(\.hr)
        guard !hrs.isEmpty else { return 0 }
        return Int(ceil(Double(hrs.reduce(0, +)) / Double(hrs.count)))
    }

    private var peakHR: Int { session.hrStream.map(\.hr).max() ?? 0 }

    private var timePerZone: [Int: TimeInterval] {
        var zones: [Int: TimeInterval] = [:]
        for record in session.hrStream {
            let z = record.currentZone
            if z >= 1 && z <= 5 { zones[z, default: 0] += 5 }
        }
        return zones
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.programType.rawValue.capitalized)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(Duration.seconds(session.durationSec).formatted(.units(allowed: [.minutes, .seconds])))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 0) {
                    StatTile(label: "Avg HR", value: "\(avgHR) bpm")
                    Divider().frame(height: 40).background(Color.white.opacity(0.2))
                    StatTile(label: "Peak HR", value: "\(peakHR) bpm")
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Time in Zones")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach(1...5, id: \.self) { zone in
                        ZoneTimeRow(
                            zone: zone,
                            seconds: timePerZone[zone] ?? 0,
                            totalSeconds: session.durationSec
                        )
                    }
                }
            }
            .padding(24)
        }
        .background(Color.black)
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ZoneTimeRow: View {
    let zone: Int
    let seconds: TimeInterval
    let totalSeconds: Int

    private var zoneColor: Color {
        switch zone {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }

    private var fraction: Double {
        totalSeconds > 0 ? seconds / Double(totalSeconds) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("Z\(zone)").font(.caption.bold()).foregroundStyle(zoneColor).frame(width: 24)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 8)
                    Capsule().fill(zoneColor).frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)
            Text(Int(seconds).durationString).font(.caption).foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
        }
    }
}

private extension Int {
    var durationString: String {
        let m = self / 60; let s = self % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
