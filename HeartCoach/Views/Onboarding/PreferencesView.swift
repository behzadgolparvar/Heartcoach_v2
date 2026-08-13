import SwiftUI
import HeartRateCoachCore

struct PreferencesView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Your Training Goals")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary Goal").font(.headline)
                    VStack(spacing: 8) {
                        ForEach([Goal.fatBurn, .endurance], id: \.self) { option in
                            SelectionRow(
                                title: option == .fatBurn ? "Fat Burn" : "Endurance",
                                subtitle: option == .fatBurn
                                    ? "Optimised for lower intensity, longer sessions"
                                    : "Build cardiovascular capacity and stamina",
                                isSelected: vm.goal == option
                            ) { vm.goal = option }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred Workout").font(.headline)
                    VStack(spacing: 8) {
                        ForEach([WorkoutType.continuous, .hiit, .fartlek], id: \.self) { option in
                            SelectionRow(
                                title: option.displayName,
                                subtitle: option.description,
                                isSelected: vm.preferredWorkout == option
                            ) { vm.preferredWorkout = option }
                        }
                    }
                }

                Button("Next →") { vm.advanceStep() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("onboarding-step3-next")
            }
            .padding(24)
        }
        .background(Color.black)
        .foregroundStyle(.white)
    }
}

private extension WorkoutType {
    var description: String {
        switch self {
        case .continuous: return "Steady progressive effort, 35 min"
        case .hiit: return "High-intensity intervals, 35 min"
        case .fartlek: return "Varied pace training, 35 min"
        }
    }
}

private struct SelectionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.red)
                }
            }
            .padding(14)
            .background(isSelected ? Color.red.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 1)
            )
        }
        .foregroundStyle(.white)
    }
}
