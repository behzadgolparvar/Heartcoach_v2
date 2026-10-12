import SwiftUI
import HeartRateCoachCore

/// Per-session Shape pre-start (§Phase 3): pick Option A/B and, for B, rank exactly
/// two muscle groups. Then starts the assigned workout type.
struct ShapeChoiceView: View {
    let assignedType: WorkoutType
    let defaultOption: ShapeOption
    let focusDefaults: [MuscleGroup]
    let onFinish: () -> Void
    @Environment(WorkoutViewModel.self) private var workoutVM

    @State private var option: ShapeOption = .weights
    @State private var priority: MuscleGroup?
    @State private var secondary: MuscleGroup?
    @State private var navigate = false
    @State private var didInit = false

    private var choice: ShapeSessionChoice {
        ShapeSessionChoice(option: option, priority: option == .weights ? priority : nil,
                           secondary: option == .weights ? secondary : nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Today: \(assignedType.displayName)")
                    .font(.headline).foregroundStyle(.secondary)

                Picker("Option", selection: $option) {
                    Text("Option A — Outdoor / no equipment").tag(ShapeOption.plyometric)
                    Text("Option B — Treadmill + weights").tag(ShapeOption.weights)
                }.pickerStyle(.segmented)

                if option == .weights {
                    musclePicker(title: "Priority muscle", selection: $priority, exclude: secondary)
                    musclePicker(title: "Secondary muscle", selection: $secondary, exclude: priority)
                } else {
                    Text("Plyometric leg exercises, 20 reps each.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                Button("Start") {
                    workoutVM.shapeChoice = choice
                    workoutVM.start(program: assignedType == .hiit ? .hiit : .continuous)
                    navigate = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!choice.isValid)
                .accessibilityIdentifier("shape-choice-start")
            }
            .padding(24)
        }
        .background(Color.black)
        .navigationTitle("Shape")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didInit else { return }
            didInit = true
            option = defaultOption
            priority = focusDefaults.first
            secondary = focusDefaults.dropFirst().first
        }
        .navigationDestination(isPresented: $navigate) {
            WorkoutView(onFinish: onFinish).environment(workoutVM)
        }
    }

    private func musclePicker(title: String, selection: Binding<MuscleGroup?>, exclude: MuscleGroup?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                Text("Not set").tag(Optional<MuscleGroup>.none)
                ForEach(MuscleGroup.allCases.filter { $0 != exclude }, id: \.self) {
                    Text($0.displayName).tag(Optional($0))
                }
            }.pickerStyle(.menu)
        }
    }
}
