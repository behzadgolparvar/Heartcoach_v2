import SwiftUI

struct PhysiologicalDataView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Your Body Data")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("Age").font(.headline)
                    TextField("e.g. 32", text: $vm.ageText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("onboarding-age-field")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resting Heart Rate").font(.headline)
                    TextField("e.g. 62", text: $vm.rhrText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("onboarding-rhr-field")
                    Text("Find this in Apple Health → Summary → Heart → Resting Heart Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let warning = vm.rhrWarning {
                    WarningBanner(message: warning == .belowTypicalRange
                        ? "Your RHR is below the typical range (40–100 bpm). Please confirm it's correct."
                        : "Your RHR is above the typical range (40–100 bpm). Please confirm it's correct.")
                }

                if let error = vm.fieldError {
                    ErrorBanner(message: error)
                }

                HealthKitAuthButton(vm: vm)

                Button("Next →") { vm.advanceStep() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("onboarding-step1-next")
            }
            .padding(24)
        }
        .background(Color.black)
        .foregroundStyle(.white)
    }
}

private struct HealthKitAuthButton: View {
    let vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if vm.isHealthKitAuthorized {
                Label("Heart Rate Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
            } else {
                Button {
                    vm.requestHealthKitAccess()
                } label: {
                    Label("Allow Heart Rate Access", systemImage: "heart.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(vm.isRequestingHealthKit)
            }
        }
    }
}
