import SwiftUI
import UIKit
import HeartRateCoachCore

struct HomeView: View {
    @Environment(HomeViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AppContainer.self) private var container
    @Environment(\.scenePhase) private var scenePhase
    @State private var workoutVM: WorkoutViewModel?
    @State private var showPreStart = false
    @State private var showMinimumWalk = false
    @State private var showLevelUpUnlock = false
    @State private var showShapeUnlock = false
    @State private var showShapeChoice = false
    @State private var weightText = ""
    @State private var pdfURL: URL?
    @State private var showShare = false
    @State private var didRequestNotifications = false

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

                    // Biweekly milestone check-in (§H).
                    if vm.isMilestoneDue {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Biweekly check-in")
                                .font(.headline).foregroundStyle(.white)
                            Text("Log your weight — we'll record your resting heart rate automatically.")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                TextField("Weight (kg)", text: $weightText)
                                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                                    .accessibilityIdentifier("milestone-weight-field")
                                Button("Log") {
                                    if let uid = authViewModel.currentUserID {
                                        vm.logMilestone(weightKg: Double(weightText), userID: uid)
                                        weightText = ""
                                    }
                                }.buttonStyle(.borderedProminent)
                            }
                            if vm.weightGate == .blockWorkout {
                                Text("Please log your weight to start your next workout.")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    // Today's assigned session (Phase 3).
                    if let a = vm.assignment {
                        TodaysSessionCard(assignment: a)
                        if a.isStageComplete, vm.profile?.program?.currentStage == .foundation {
                            Button("Unlock Level Up") { showLevelUpUnlock = true }
                                .buttonStyle(PrimaryButtonStyle())
                                .accessibilityIdentifier("home-unlock-levelup")
                        }
                        if a.isStageComplete, vm.profile?.program?.currentStage == .levelUp {
                            Button("Unlock Shape") { showShapeUnlock = true }
                                .buttonStyle(PrimaryButtonStyle())
                                .accessibilityIdentifier("home-unlock-shape")
                        }
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
                                    maxHR: profile.effectiveMaxHR,
                                    stage: profile.program?.currentStage ?? .foundation,
                                    levelUpUnlock: profile.levelUpUnlock)
                                if profile.program?.currentStage == .shape {
                                    showShapeChoice = true
                                } else {
                                    showPreStart = true
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!vm.isHealthKitAuthorized || vm.zones == nil || vm.isWorkoutBlockedForWeight)
                        .accessibilityIdentifier("home-start-workout")

                        Button("Not feeling it? Do your 15-min minimum") {
                            showMinimumWalk = true
                        }
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)
                        .disabled(vm.zones == nil)

                        Button("View my plan (PDF)") { generatePlan() }
                            .font(.footnote.bold())
                            .foregroundStyle(.secondary)
                            .disabled(vm.profile?.program == nil)
                            .accessibilityIdentifier("home-view-plan")

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
            .navigationDestination(isPresented: $showLevelUpUnlock) {
                LevelUpUnlockView(prefilledInjuredJoints: vm.prefilledInjuredJoints) { injured, comfortable, approved in
                    if let userID = authViewModel.currentUserID {
                        vm.completeLevelUpUnlock(injuredJoints: injured, comfortable: comfortable,
                                                 approvedExerciseIDs: approved, userID: userID)
                    }
                    showLevelUpUnlock = false
                }
            }
            .navigationDestination(isPresented: $showShapeUnlock) {
                ShapeUnlockView { equipment, focus, pain in
                    if let userID = authViewModel.currentUserID {
                        vm.completeShapeUnlock(equipmentPreference: equipment, focusAreas: focus,
                                               acknowledgedPain: pain, userID: userID)
                    }
                    showShapeUnlock = false
                }
            }
            .navigationDestination(isPresented: $showShapeChoice) {
                if let wvm = workoutVM, let a = vm.assignment {
                    ShapeChoiceView(assignedType: a.type,
                                    defaultOption: vm.profile?.shapeUnlock?.equipmentPreference ?? .weights,
                                    focusDefaults: Array(vm.profile?.shapeUnlock?.focusAreas ?? []),
                                    onFinish: { showShapeChoice = false; workoutVM = nil })
                    .environment(wvm)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
        .onAppear {
            if let userID = authViewModel.currentUserID {
                vm.loadData(userID: userID)
            }
            if !didRequestNotifications {
                didRequestNotifications = true
                Task { _ = await container.notificationService.requestAuthorization() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { vm.recheckHealthKitStatus() }
        }
    }

    private func generatePlan() {
        guard let profile = vm.profile, let stage = profile.program?.currentStage else { return }
        let rows = SessionPlanBuilder.plan(stage: stage, profile: profile)
        let note = SessionPlanBuilder.projectedCompletionNote(
            frequencyPerWeek: profile.schedule.frequencyPerWeek, stage: stage)
        if let url = container.pdfRenderer.render(stage: stage, rows: rows, completionNote: note) {
            pdfURL = url
            showShare = true
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

// MARK: - Share sheet (PDF export)

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
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
