import SwiftUI
import HeartRateCoachCore

struct ZoneDetailView: View {
    let zones: HRZones

    private let zoneDescriptions: [Int: String] = [
        1: "Very light effort. Active recovery, warm-up, and cool-down.",
        2: "Light effort. The primary fat-burning zone. Comfortable conversational pace.",
        3: "Moderate effort. Improves aerobic fitness and cardiovascular efficiency.",
        4: "Hard effort. Increases maximum performance and raises lactate threshold.",
        5: "Maximum effort. Short bursts only. Develops speed and peak power."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach([zones.zone1, zones.zone2, zones.zone3, zones.zone4, zones.zone5], id: \.number) { zone in
                    VStack(alignment: .leading, spacing: 8) {
                        ZoneRowView(zone: zone)
                        if let desc = zoneDescriptions[zone.number] {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        }
                    }
                    if zone.number < 5 { Divider().background(Color.white.opacity(0.1)) }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(24)
        }
        .background(Color.black)
        .navigationTitle("Heart Rate Zones")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("zone-detail-view")
    }
}
