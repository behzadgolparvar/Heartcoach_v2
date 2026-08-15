import SwiftUI
import HeartRateCoachCore

struct WorkoutView: View {
    let onFinish: () -> Void
    @Environment(WorkoutViewModel.self) private var workoutVM
    @State private var showEmergencyStop = false
    @State private var navigateToSummary = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch workoutVM.startupState {
            case .warmingUp:
                startupView(big: nil, caption: "Getting your heart rate…", showSpinner: true)
            case .countdown(let n):
                startupView(big: "\(n)", caption: "Get ready", showSpinner: false)
            case .running:
                runningContent
            }

            // Emergency stop overlay
            if showEmergencyStop {
                EmergencyStopOverlay(onConfirm: {
                    workoutVM.emergencyStop()
                    showEmergencyStop = false
                    navigateToSummary = true
                }, onCancel: {
                    showEmergencyStop = false
                })
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEmergencyStop = true
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
                .accessibilityIdentifier("emergency-stop-button")
            }
        }
        .onChange(of: workoutVM.isWorkoutActive) { _, active in
            if !active, workoutVM.completedSession != nil {
                navigateToSummary = true
            }
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            if let session = workoutVM.completedSession {
                WorkoutSummaryView(session: session, onFinish: onFinish)
            }
        }
    }

    // MARK: - Sub-Views

    private var runningContent: some View {
        VStack(spacing: 0) {
            phaseHeader

            Spacer()

            if workoutVM.isPaused {
                pausedContent
            } else {
                activeContent
            }

            Spacer()

            if let msg = workoutVM.coachingState?.coachingMessage {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                    .animation(.easeInOut, value: msg)
            }

            controlButtons
                .padding(.bottom, 40)
        }
        .padding(.top, 16)
    }

    private func startupView(big: String?, caption: String, showSpinner: Bool) -> some View {
        VStack(spacing: 24) {
            if let big {
                Text(big)
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .transition(.scale.combined(with: .opacity))
                    .id(big)
            } else if showSpinner {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
            Text(caption)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy, value: big)
    }

    private var phaseHeader: some View {
        VStack(spacing: 4) {
            if let state = workoutVM.coachingState {
                Text(state.phase.displayName)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Label(state.elapsedTime.formatted, systemImage: "timer")
                    if let target = state.targetZone {
                        Label("Target: Zone \(target)", systemImage: "target")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }

    private var activeContent: some View {
        VStack(spacing: 20) {
            ZoneRingView(
                zone: workoutVM.coachingState?.currentZone ?? 0,
                hr: workoutVM.coachingState?.currentHR ?? 0,
                targetZone: workoutVM.coachingState?.targetZone
            )

            if let state = workoutVM.coachingState, state.isGracePeriodActive {
                Text("Grace period — settle in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }

            if let state = workoutVM.coachingState {
                HStack {
                    Text("Phase ends in")
                    Text(state.phaseTimeRemaining.formatted)
                        .bold()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var pausedContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white.opacity(0.4))
            Text("Paused")
                .font(.title.bold())
                .foregroundStyle(.white)
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            if workoutVM.isPaused {
                Button("Resume") { workoutVM.resume() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("workout-resume-button")

                Button("End Workout") { workoutVM.end() }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("workout-end-button")
            } else {
                Button("Pause") { workoutVM.pause() }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("workout-pause-button")
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Helpers

private extension PhaseType {
    var displayName: String {
        switch self {
        case .warmup: return "Warm Up"
        case .exercise: return "Exercise"
        case .recovery: return "Recovery"
        case .cooldown: return "Cool Down"
        }
    }
}

private extension TimeInterval {
    var formatted: String {
        let mins = Int(self) / 60
        let secs = Int(self) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
