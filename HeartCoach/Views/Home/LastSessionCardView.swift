import SwiftUI
import HeartRateCoachCore

struct LastSessionCardView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Session")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Label(session.date.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                Spacer()
                Label("\(session.durationSec / 60) min", systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "heart.fill").foregroundStyle(.red)
                Text("Avg HR: \(session.avgHR) bpm")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            // Time-in-zones mini bar
            if !session.timeInZones.isEmpty {
                ZoneBarView(timeInZones: session.timeInZones, totalSec: session.durationSec)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct ZoneBarView: View {
    let timeInZones: [Int: Int]
    let totalSec: Int

    private let zoneColors: [Int: Color] = [
        1: .blue, 2: .green, 3: .yellow, 4: .orange, 5: .red
    ]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { zone in
                    let seconds = timeInZones[zone] ?? 0
                    let fraction = totalSec > 0 ? CGFloat(seconds) / CGFloat(totalSec) : 0
                    Rectangle()
                        .fill(zoneColors[zone] ?? .gray)
                        .frame(width: geo.size.width * fraction)
                        .opacity(seconds > 0 ? 1 : 0.15)
                }
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }
}
