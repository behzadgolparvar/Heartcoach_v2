import SwiftUI
import HeartRateCoachCore

/// Reusable row displaying a single HR zone's number, name, and bpm range.
struct ZoneRowView: View {
    let zone: Zone

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(WT.zoneColor(zone.number))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text("Zone \(zone.number)").font(.caption).foregroundStyle(.secondary)
                Text(zone.name).font(.subheadline.bold()).foregroundStyle(.white)
            }

            Spacer()

            Text("\(zone.min)–\(zone.max) bpm")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
