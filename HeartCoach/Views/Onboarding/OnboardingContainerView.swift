import SwiftUI

struct OnboardingContainerView: View {
    @Environment(OnboardingViewModel.self) private var vm

    private var stepIndex: Int {
        switch vm.currentStep {
        case .physiologicalData: return 0
        case .optionalDetails: return 1
        case .preferences: return 2
        case .zonePreview: return 3
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch vm.currentStep {
                case .physiologicalData: PhysiologicalDataView()
                case .optionalDetails:   OptionalDetailsView()
                case .preferences:       PreferencesView()
                case .zonePreview:       ZonePreviewView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    StepIndicator(currentStep: stepIndex, totalSteps: 4)
                }
                if vm.currentStep != .physiologicalData && vm.currentStep != .zonePreview {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") { vm.goBack() }
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Circle()
                    .fill(i <= currentStep ? Color.red : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
