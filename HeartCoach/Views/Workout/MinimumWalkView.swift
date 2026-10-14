import SwiftUI
import HeartRateCoachCore

struct MinimumWalkView: View {
    @State private var vm: MinimumWalkViewModel
    let onDone: () -> Void

    init(voiceFeedback: VoiceFeedbackServiceProtocol, onDone: @escaping () -> Void) {
        _vm = State(initialValue: MinimumWalkViewModel(voiceFeedback: voiceFeedback))
        self.onDone = onDone
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                Text(segmentTitle)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("15-minute minimum · keeps your momentum, doesn't affect your progression")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 12)

                if vm.segment == .done {
                    Button("Done") { onDone() }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("minimum-done-button")
                } else {
                    Button("Finish") { vm.finishEarly() }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("minimum-finish-button")
                }
            }
            .padding(24)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            vm.onComplete = { onDone() }
            vm.start()
        }
        .onDisappear { vm.stop() }
    }

    private var segmentTitle: String {
        switch vm.segment {
        case .fast: return "Brisk pace"
        case .slow: return "Easy pace"
        case .done: return "Complete"
        }
    }

    private var timeString: String {
        let m = vm.secondsRemaining / 60, s = vm.secondsRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}
