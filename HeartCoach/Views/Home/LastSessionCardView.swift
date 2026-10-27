import SwiftUI
import HeartRateCoachCore

/// Direction D "broadcast" restyle of the last-session recap (Home A6).
struct LastSessionCardView: View {
    let session: Session

    private var zonesWithTime: [(zone: Int, sec: Int)] {
        (1...5).compactMap { z in
            let s = session.timeInZones[z] ?? 0
            return s > 0 ? (z, s) : nil
        }
    }
    private var zonedTotal: Int { zonesWithTime.reduce(0) { $0 + $1.sec } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Last session")
                    .font(WT.body(16, .bold)).foregroundStyle(.white)
                Spacer()
                Text("\(dateText) · \(session.programType.displayName)")
                    .font(WT.body(13, .medium)).foregroundStyle(WT.textSecondary)
            }

            HStack(spacing: 22) {
                stat(value: "\(session.avgHR)", unit: " avg bpm")
                if let pct = session.scorePercent {
                    stat(value: "\(Int(pct.rounded()))%", unit: " in target")
                }
            }

            if zonedTotal > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(zonesWithTime, id: \.zone) { item in
                            Rectangle()
                                .fill(WT.zoneColor(item.zone))
                                .frame(width: geo.size.width * CGFloat(item.sec) / CGFloat(zonedTotal))
                        }
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())

                HStack(spacing: 14) {
                    ForEach(zonesWithTime, id: \.zone) { item in
                        HStack(spacing: 5) {
                            Circle().fill(WT.zoneColor(item.zone)).frame(width: 6, height: 6)
                            Text("Z\(item.zone) \(item.sec / 60)m")
                                .font(WT.body(12, .medium)).foregroundStyle(WT.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
        .background(Color(hex: 0x141416))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(WT.panelStroke, lineWidth: 1))
    }

    private var dateText: String {
        session.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private func stat(value: String, unit: String) -> some View {
        (Text(value).font(WT.body(26, .bold)).foregroundStyle(.white)
         + Text(unit).font(WT.body(13, .medium)).foregroundStyle(WT.textSecondary))
    }
}
