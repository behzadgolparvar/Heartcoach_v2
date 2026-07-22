import SwiftUI

struct IdleWatchView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(.red)
            Text("HeartCoach")
                .font(.headline)
            Text("Start workout on iPhone")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
