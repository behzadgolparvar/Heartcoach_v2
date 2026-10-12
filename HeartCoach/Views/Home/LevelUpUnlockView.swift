import SwiftUI
import HeartRateCoachCore

/// The Level Up unlock questions (§E): injury (pre-filled from onboarding) +
/// comfort with bodyweight exercises (+ approved subset). On completion it hands
/// back the answers so Home can store them and advance the stage.
struct LevelUpUnlockView: View {
    let prefilledInjuredJoints: Set<LegJoint>
    let onComplete: (_ injured: Set<LegJoint>, _ comfortable: Bool, _ approved: Set<String>?) -> Void

    @State private var injured: Set<LegJoint> = []
    @State private var comfortable = true
    @State private var approved: Set<String> = []
    @State private var didInit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome to Level Up")
                    .font(.title2.bold()).foregroundStyle(.white)
                Text("You'll now add short standing leg exercises to your runs. A couple of quick questions first.")
                    .font(.subheadline).foregroundStyle(.secondary)

                // Q1 — injuries
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any leg, knee, hip, or ankle injuries in the past year?")
                        .font(.headline).foregroundStyle(.white)
                    ForEach(LegJoint.allCases, id: \.self) { joint in
                        Toggle(joint.rawValue.capitalized, isOn: Binding(
                            get: { injured.contains(joint) },
                            set: { on in if on { injured.insert(joint) } else { injured.remove(joint) } }))
                        .tint(.red).foregroundStyle(.white)
                    }
                    if !injured.isEmpty {
                        Text("Since you mentioned a recent injury, we've adjusted your exercises. If you feel pain during any movement, stop and consult a doctor before continuing.")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }

                // Q2 — comfort
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("I'm comfortable doing bodyweight exercises like squats or lunges",
                           isOn: $comfortable).tint(.red).foregroundStyle(.white)
                    if !comfortable {
                        Text("Pick the exercises you're willing to do:")
                            .font(.subheadline).foregroundStyle(.secondary)
                        ForEach(eligibleBank, id: \.id) { ex in
                            Toggle(ex.name, isOn: Binding(
                                get: { approved.contains(ex.id) },
                                set: { on in if on { approved.insert(ex.id) } else { approved.remove(ex.id) } }))
                            .tint(.red).foregroundStyle(.white)
                        }
                    }
                }

                Button("Start Level Up") {
                    onComplete(injured, comfortable, comfortable ? nil : approved)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!comfortable && approved.isEmpty)
                .accessibilityIdentifier("levelup-unlock-start")
            }
            .padding(24)
        }
        .background(Color.black)
        .navigationTitle("Level Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !didInit { injured = prefilledInjuredJoints; didInit = true }
        }
    }

    /// Bank filtered to the current injury selection (for the comfort subset picker).
    private var eligibleBank: [LegExercise] {
        LegExerciseBank.all.filter { $0.impactedJoints.isDisjoint(with: injured) }
    }
}
