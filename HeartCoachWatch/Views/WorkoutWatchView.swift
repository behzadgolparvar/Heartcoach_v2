import SwiftUI

struct WorkoutWatchView: View {
    @Environment(WorkoutWatchViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 4) {
            Text(viewModel.phaseName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("\(viewModel.currentHR)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(zoneColor(viewModel.currentZone))
                .minimumScaleFactor(0.6)
                .accessibilityLabel("\(viewModel.currentHR) beats per minute")

            Text("BPM")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(zoneLabel(viewModel.currentZone))
                .font(.caption)
                .foregroundStyle(zoneColor(viewModel.currentZone))

            if let message = viewModel.lastMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Helpers

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }

    private func zoneLabel(_ zone: Int) -> String {
        zone >= 1 && zone <= 5 ? "Zone \(zone)" : "—"
    }
}
