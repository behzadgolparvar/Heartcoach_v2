import SwiftUI

struct EmergencyStopOverlay: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)

                Text("Emergency Stop")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Are you sure you want to stop the workout immediately?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    Button("Stop Workout") {
                        onConfirm()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .tint(.red)
                    .accessibilityIdentifier("emergency-confirm-button")

                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("emergency-cancel-button")
                }
                .padding(.horizontal, 32)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}
