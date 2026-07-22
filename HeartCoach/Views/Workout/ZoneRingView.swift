import SwiftUI

struct ZoneRingView: View {
    let zone: Int        // 0–6; 0 = no signal, 1–5 = in zone, 6 = above HRmax
    let hr: Int
    let targetZone: Int?

    private var zoneColor: Color {
        switch zone {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        case 6: return .purple
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 16)

            Circle()
                .trim(from: 0, to: zone > 0 ? 1 : 0)
                .stroke(zoneColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: zone)

            VStack(spacing: 4) {
                if hr > 0 {
                    Text("\(hr)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("BPM")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.gray)
                    Text("No signal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if zone >= 1 && zone <= 5 {
                    Text("Zone \(zone)")
                        .font(.subheadline.bold())
                        .foregroundStyle(zoneColor)
                        .padding(.top, 4)
                }
            }
        }
        .frame(width: 220, height: 220)
        .accessibilityLabel(hr > 0 ? "Zone \(zone), \(hr) BPM" : "No heart rate signal")
    }
}
