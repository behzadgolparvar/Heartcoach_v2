import SwiftUI
import HeartRateCoachCore

struct WorkoutPreStartView: View {
    var assignedType: WorkoutType? = nil
    let onFinish: () -> Void
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
                    subtitle: "Steady progressive effort",
                    phases: "7 blocks · 35 min + cooldown",
                    program: .continuous,
                    selectedProgram: $selectedProgram
                )

                ProgramCard(
                    subtitle: "High-intensity intervals",
                    phases: "15 rounds · 35 min + cooldown",
                    program: .hiit,
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
        .onAppear {
            // Pre-select today's assigned session (Q9); the user can still override.
            if selectedProgram == nil, let t = assignedType {
                selectedProgram = (t == .hiit) ? .hiit : .continuous
            }
        }
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView(onFinish: onFinish)
                .environment(workoutVM)
        }
    }
}

private struct ProgramCard: View {
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
                Text(program.displayName)
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
        .accessibilityIdentifier("program-card-\(program.displayName.lowercased())")
    }
}
