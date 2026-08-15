import SwiftUI
import HeartRateCoachCore

struct OptionalDetailsView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optional Details")
                        .font(.title.bold())
                    Text("You can skip this step.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Biological Sex").font(.headline)
                    Picker("Sex", selection: $vm.sex) {
                        Text("Not specified").tag(Optional<Sex>.none)
                        Text("Male").tag(Optional<Sex>.some(.male))
                        Text("Female").tag(Optional<Sex>.some(.female))
                        Text("Other").tag(Optional<Sex>.some(.other))
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)").font(.headline)
                    TextField("e.g. 75", text: $vm.weightText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 12) {
                    Button("Skip") { vm.advanceStep() }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("onboarding-step2-skip")

                    Button("Next →") { vm.advanceStep() }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("onboarding-step2-next")
                }
            }
            .padding(24)
            .hideKeyboardOnTap()
        }
        .background(Color.black)
        .foregroundStyle(.white)
        .dismissableKeyboard()
    }
}
