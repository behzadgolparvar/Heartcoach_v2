import SwiftUI
import HeartRateCoachCore

struct WorkoutSummaryView: View {
    let session: Session
    let onFinish: () -> Void
    @Environment(WorkoutSummaryViewModel.self) private var summaryVM
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.programType.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(Duration.seconds(session.durationSec).formatted(.units(allowed: [.minutes, .seconds])))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats row
                HStack(spacing: 0) {
                    StatTile(label: "Avg HR", value: "\(summaryVM.avgHR) bpm")
                    Divider().frame(height: 40).background(Color.white.opacity(0.2))
                    StatTile(label: "Peak HR", value: "\(summaryVM.peakHR) bpm")
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Time in zones
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time in Zones")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach(1...5, id: \.self) { zone in
                        ZoneTimeRow(
                            zone: zone,
                            seconds: summaryVM.timePerZone[zone] ?? 0,
                            totalSeconds: session.durationSec
                        )
                    }
                }

                // Save button
                VStack(spacing: 8) {
                    switch summaryVM.saveState {
                    case .idle:
                        Button("Save Workout") {
                            if let uid = authVM.currentUserID {
                                summaryVM.saveSession(userID: uid)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("summary-save-button")

                    case .saving:
                        ProgressView("Saving…").tint(.white)

                    case .saved:
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)

                    case .savedPendingSync:
                        Label("Saved — will sync when online", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)

                    case .failed(let error):
                        ErrorBanner(message: error.localizedDescription)
                        Button("Retry") {
                            if let uid = authVM.currentUserID {
                                summaryVM.saveSession(userID: uid)
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    Button("Done") { onFinish() }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("summary-done-button")
                }
            }
            .padding(24)
        }
        .background(Color.black)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear { summaryVM.load(session: session) }
    }
}

private struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
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
            Text("Z\(zone)")
                .font(.caption.bold())
                .foregroundStyle(zoneColor)
                .frame(width: 24)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 8)
                    Capsule().fill(zoneColor).frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)

            Text(Int(seconds).durationString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

private extension Int {
    var durationString: String {
        let m = self / 60
        let s = self % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
