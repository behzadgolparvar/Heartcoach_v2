import SwiftUI
import HeartRateCoachCore

struct HomeView: View {
    @Environment(HomeViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AppContainer.self) private var container
    @Environment(\.scenePhase) private var scenePhase
    @State private var workoutVM: WorkoutViewModel?
    @State private var showPreStart = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Good \(timeOfDayGreeting())!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    // Zone card (empty state) or last session card
                    if let session = vm.lastSession {
                        LastSessionCardView(session: session)
                    } else if let zones = vm.zones {
                        ZoneCardView(zones: zones)
                    } else if vm.isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity)
                    }

                    // Start Workout button
                    VStack(spacing: 8) {
                        Button("Start Workout") {
                            if let zones = vm.zones {
                                workoutVM = container.makeWorkoutViewModel(zones: zones)
                                showPreStart = true
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!vm.isHealthKitAuthorized || vm.zones == nil)
                        .accessibilityIdentifier("home-start-workout")

                        if !vm.isHealthKitAuthorized {
                            VStack(spacing: 6) {
                                Text("Heart rate access is required to use HeartCoach.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Grant Heart Rate Access →") {
                                    vm.requestHealthKitAccess()
                                }
                                .font(.footnote.bold())
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.black)
            .navigationTitle("HeartCoach")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showPreStart) {
                if let wvm = workoutVM {
                    WorkoutPreStartView(onFinish: {
                        // Collapse the entire workout stack back to Home.
                        showPreStart = false
                        workoutVM = nil
                    })
                    .environment(wvm)
                }
            }
        }
        .onAppear {
            if let userID = authViewModel.currentUserID {
                vm.loadData(userID: userID)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { vm.recheckHealthKitStatus() }
        }
    }

    private func timeOfDayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
}
