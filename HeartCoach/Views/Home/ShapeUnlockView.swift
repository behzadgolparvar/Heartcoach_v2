import SwiftUI
import HeartRateCoachCore

/// Shape unlock questions (§E): equipment preference (sets the default daily Option),
/// a Level-Up-pain safety acknowledgement, and focus areas (prime the muscle picker).
struct ShapeUnlockView: View {
    let onComplete: (_ equipment: ShapeOption, _ focus: Set<MuscleGroup>, _ acknowledgedPain: Bool) -> Void

    @State private var equipment: ShapeOption = .weights
    @State private var focus: Set<MuscleGroup> = []
    @State private var hadPain = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome to Shape")
                    .font(.title2.bold()).foregroundStyle(.white)
                Text("You'll now choose how to train each day — outdoor/no-equipment or treadmill + weights — and target specific muscle groups.")
                    .font(.subheadline).foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Do you usually have a treadmill and free weights, or prefer outdoor/no-equipment?")
                        .font(.headline).foregroundStyle(.white)
                    Picker("Equipment", selection: $equipment) {
                        Text("Treadmill + weights (Option B)").tag(ShapeOption.weights)
                        Text("Outdoor / no equipment (Option A)").tag(ShapeOption.plyometric)
                    }.pickerStyle(.segmented)
                    Text("You can still switch every session.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("I had pain or discomfort during Level Up sessions", isOn: $hadPain)
                        .tint(.red).foregroundStyle(.white)
                    if hadPain {
                        Text("If you feel pain during any movement, stop and consult a doctor before continuing.")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Which areas would you like to focus on most?")
                        .font(.headline).foregroundStyle(.white)
                    ForEach(MuscleGroup.allCases, id: \.self) { m in
                        Toggle(m.displayName, isOn: Binding(
                            get: { focus.contains(m) },
                            set: { on in if on { focus.insert(m) } else { focus.remove(m) } }))
                        .tint(.red).foregroundStyle(.white)
                    }
                }

                Button("Start Shape") { onComplete(equipment, focus, hadPain) }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("shape-unlock-start")
            }
            .padding(24)
        }
        .background(Color.black)
        .navigationTitle("Shape")
        .navigationBarTitleDisplayMode(.inline)
    }
}
