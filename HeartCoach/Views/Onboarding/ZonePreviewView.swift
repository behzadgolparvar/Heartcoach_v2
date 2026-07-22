import SwiftUI
import HeartRateCoachCore

struct ZonePreviewView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your Personalised Zones")
                    .font(.title.bold())

                if let zones = vm.computedZones {
                    VStack(spacing: 0) {
                        ForEach([zones.zone1, zones.zone2, zones.zone3, zones.zone4, zones.zone5], id: \.number) { zone in
                            ZoneRowView(zone: zone)
                            if zone.number < 5 { Divider().background(Color.white.opacity(0.1)) }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if vm.isSaving {
                    HStack {
                        Spacer()
                        ProgressView("Saving…").tint(.white)
                        Spacer()
                    }
                } else {
                    Button("Start Training") {
                        if let userID = authViewModel.authService.currentUserID {
                            vm.saveProfile(userID: userID)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("onboarding-start-training")
                }

                if let error = vm.fieldError {
                    ErrorBanner(message: error)
                }
            }
            .padding(24)
        }
        .background(Color.black)
        .foregroundStyle(.white)
    }
}
