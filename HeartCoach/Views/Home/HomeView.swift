import SwiftUI
import HeartRateCoachCore

struct HomeView: View {
    @Environment(HomeViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AppContainer.self) private var container
    @Environment(\.scenePhase) private var scenePhase
    @State private var workoutVM: WorkoutViewModel?
    @State private var showPreStart = false
    @State private var showMinimumWalk = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Good \(timeOfDayGreeting())!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    // Positive re-entry message after a relapse push-back (§C).
                    if let msg = vm.relapseMessage {
                        Text(msg)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.18)))
                    }

                    // Today's assigned session (Phase 3).
                    if let a = vm.assignment {
                        TodaysSessionCard(assignment: a)
                    }

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
                        Button(startButtonTitle) {
                            if let zones = vm.zones, let profile = vm.profile {
                                workoutVM = container.makeWorkoutViewModel(
                                    zones: zones,
                                    restingHR: profile.restingHR,
                                    maxHR: profile.effectiveMaxHR)
                                showPreStart = true
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!vm.isHealthKitAuthorized || vm.zones == nil)
                        .accessibilityIdentifier("home-start-workout")

                        Button("Not feeling it? Do your 15-min minimum") {
                            showMinimumWalk = true
                        }
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .disabled(vm.zones == nil)

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
                    WorkoutPreStartView(assignedType: vm.assignment?.type, onFinish: {
                        // Collapse the entire workout stack back to Home.
                        showPreStart = false
                        workoutVM = nil
                    })
                    .environment(wvm)
                }
            }
            .navigationDestination(isPresented: $showMinimumWalk) {
                MinimumWalkView(voiceFeedback: container.voiceFeedbackService) {
                    if let userID = authViewModel.currentUserID {
                        vm.recordMinimumWalk(userID: userID)
                    }
                    showMinimumWalk = false
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

    private var startButtonTitle: String {
        guard let a = vm.assignment, !a.isStageComplete else { return "Start Workout" }
        return "Start \(a.type.displayName)"
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

// MARK: - Today's session card

private struct TodaysSessionCard: View {
    let assignment: SessionAssignment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if assignment.isStageComplete {
                Text("Foundation complete 🎉")
                    .font(.headline).foregroundStyle(.white)
                Text("Level Up is coming soon. Keep training at your current level in the meantime.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Text("Today's session")
                    .font(.caption).foregroundStyle(.secondary)
                Text(assignment.type.displayName)
                    .font(.title3.bold()).foregroundStyle(.white)
                Text("Session \(assignment.sessionNumber) of 60 · Sub-phase \(assignment.subPhase + 1)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }
}
