import SwiftUI
import HeartRateCoachCore

struct WorkoutPreStartView: View {
    @Environment(WorkoutViewModel.self) private var workoutVM
    @State private var navigateToWorkout = false
    @State private var selectedProgram: WorkoutProgram?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose a Program")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ProgramCard(
                    title: "Continuous",
                    subtitle: "Steady progressive effort",
                    phases: "12 phases · 35 min",
                    program: .continuous,
                    selectedProgram: $selectedProgram
                )

                ProgramCard(
                    title: "HIIT",
                    subtitle: "High-intensity intervals",
                    phases: "32 phases · 35 min",
                    program: .hiit,
                    selectedProgram: $selectedProgram
                )

                ProgramCard(
                    title: "Fartlek",
                    subtitle: "Varied pace, your call",
                    phases: "17 phases · 35 min",
                    program: .fartlek,
                    selectedProgram: $selectedProgram
                )

                Button("Start") {
                    if let program = selectedProgram {
                        workoutVM.start(program: program)
                        navigateToWorkout = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedProgram == nil)
                .accessibilityIdentifier("prestart-start-button")
            }
            .padding(24)
        }
        .background(Color.black)
        .navigationTitle("HeartCoach")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView()
        }
    }
}

private struct ProgramCard: View {
    let title: String
    let subtitle: String
    let phases: String
    let program: WorkoutProgram
    @Binding var selectedProgram: WorkoutProgram?

    private var isSelected: Bool { selectedProgram == program }

    var body: some View {
        Button {
            selectedProgram = program
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(phases)
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.red.opacity(0.2) : Color(.systemGray6).opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Color.red : Color.clear, lineWidth: 2)
                    )
            )
        }
        .accessibilityIdentifier("program-card-\(title.lowercased())")
    }
}

extension WorkoutProgram: Equatable {
    public static func == (lhs: WorkoutProgram, rhs: WorkoutProgram) -> Bool {
        switch (lhs, rhs) {
        case (.continuous, .continuous), (.hiit, .hiit), (.fartlek, .fartlek): return true
        default: return false
        }
    }
}
