import SwiftUI
import HeartRateCoachCore

struct HistoryView: View {
    @Environment(HistoryViewModel.self) private var historyVM
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        NavigationStack {
            Group {
                if historyVM.isLoading && historyVM.sessions.isEmpty {
                    ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if historyVM.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .background(Color.black)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let uid = authVM.currentUserID {
                historyVM.loadInitial(userID: uid)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No workouts yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Complete a workout to see it here.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionList: some View {
        List {
            ForEach(historyVM.sessions, id: \.id) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    SessionRow(session: session)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }

            if historyVM.hasMore {
                Button("Load More") {
                    if let uid = authVM.currentUserID {
                        historyVM.loadMore(userID: uid)
                    }
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("history-load-more-button")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

private struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.programType.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.avgHR) bpm")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                Text(Int(session.durationSec).durationString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension Int {
    var durationString: String {
        let m = self / 60
        let s = self % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
