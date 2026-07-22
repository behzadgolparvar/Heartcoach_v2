import SwiftUI
import HeartRateCoachCore

struct ZoneCardView: View {
    let zones: HRZones

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your HR Zones")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach([zones.zone1, zones.zone2, zones.zone3, zones.zone4, zones.zone5], id: \.number) { zone in
                    ZoneRowView(zone: zone)
                    if zone.number < 5 { Divider().background(Color.white.opacity(0.1)) }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            NavigationLink("View all zones →", destination: ZoneDetailView(zones: zones))
                .font(.footnote.bold())
                .foregroundStyle(.red)
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
