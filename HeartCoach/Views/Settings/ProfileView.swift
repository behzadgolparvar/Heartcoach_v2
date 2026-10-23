import SwiftUI
import HeartRateCoachCore

/// Read-only summary of the user's onboarding (level, HR zones, details) + program.
/// Nothing here is editable — to change anything, the user redoes onboarding (which
/// also resets program progress). Settings (app preferences) is reached via the gear.
struct ProfileView: View {
    @Environment(HomeViewModel.self) private var homeViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(OnboardingViewModel.self) private var onboardingVM
    @Environment(AppContainer.self) private var container

    @State private var showSettings = false
    @State private var showRedoConfirm = false
    @State private var pdfURL: URL?
    @State private var showPlan = false
    @State private var isGeneratingPlan = false

    private var profile: UserProfileV2? { homeViewModel.profile }
    private var zones: HRZones? { homeViewModel.zones }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    VStack(alignment: .leading, spacing: 28) {
                        header(profile)
                        if let zones { zoneSection(zones) }
                        detailsSection(profile)
                        programSection
                        redoSection
                    }
                    .padding(24)
                } else {
                    ProgressView().tint(.white).frame(maxWidth: .infinity).padding(.top, 80)
                }
            }
            .background(Color.black)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape.fill") }
                        .accessibilityIdentifier("profile-settings-button")
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPlan) { if let url = pdfURL { QuickLookPreview(url: url) } }
        .confirmationDialog("Redo onboarding?", isPresented: $showRedoConfirm, titleVisibility: .visible) {
            Button("Redo onboarding", role: .destructive) {
                onboardingVM.reset()
                authViewModel.appState = .onboarding
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This rebuilds your profile and resets your program progress to 0. Your past workout history is kept.")
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private func header(_ profile: UserProfileV2) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let email = authViewModel.currentUserEmail {
                Text(email).font(.subheadline).foregroundStyle(.secondary)
            }
            if let level = resolvedLevel(profile) {
                Text(level.displayName).font(.title2.bold()).foregroundStyle(.white)
            }
            if let program = profile.program {
                Text("\(program.currentStage.displayName) · \(program.currentProgress.sessionsCompleted) / 60 sessions")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private func zoneSection(_ zones: HRZones) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            title("Your HR Zones")
            VStack(spacing: 0) {
                ForEach([zones.zone1, zones.zone2, zones.zone3, zones.zone4, zones.zone5], id: \.number) { zone in
                    ZoneRowView(zone: zone)
                    if zone.number < 5 { Divider().background(Color.white.opacity(0.1)) }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func detailsSection(_ profile: UserProfileV2) -> some View {
        var rows: [(String, String)] = [
            ("Age", "\(profile.age)"),
            ("Resting HR", "\(profile.restingHR) bpm")
        ]
        if let maxHR = zones?.zone5.max { rows.append(("Max HR", "\(maxHR) bpm")) }
        rows.append(("Gender", profile.gender.displayName))
        rows.append(("Goals", profile.goals.isEmpty ? "—" : profile.goals.map(\.displayName).joined(separator: ", ")))
        if profile.healthHistory?.onAntiObesityTherapy == true {
            rows.append(("Anti-obesity therapy", "Yes"))
        }
        return VStack(alignment: .leading, spacing: 10) {
            title("Your Details")
            detailsCard(rows)
        }
    }

    private var programSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            title("Your Program")
            Button { generatePlan() } label: {
                HStack(spacing: 8) {
                    if isGeneratingPlan { ProgressView().tint(.white) }
                    Text(isGeneratingPlan ? "Preparing plan…" : "View my plan (PDF)")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(profile?.program == nil || isGeneratingPlan)
            .accessibilityIdentifier("profile-view-plan")
            Text("A printable overview of your current stage's sessions.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var redoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().background(Color.white.opacity(0.1))
            Text("To change any of your details, redo onboarding. This resets your program progress.")
                .font(.footnote).foregroundStyle(.secondary)
            Button { showRedoConfirm = true } label: {
                Text("Redo onboarding")
                    .font(.headline).foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.red.opacity(0.6), lineWidth: 1.5))
            }
            .accessibilityIdentifier("profile-redo-onboarding")
        }
    }

    // MARK: - Helpers

    private func title(_ t: String) -> some View { Text(t).font(.headline).foregroundStyle(.white) }

    private func detailsCard(_ rows: [(String, String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { i, row in
                HStack(alignment: .firstTextBaseline) {
                    Text(row.0).foregroundStyle(.secondary)
                    Spacer(minLength: 16)
                    Text(row.1).foregroundStyle(.white).multilineTextAlignment(.trailing)
                }
                .font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 12)
                if i < rows.count - 1 { Divider().background(Color.white.opacity(0.08)) }
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resolvedLevel(_ profile: UserProfileV2) -> FitnessExperience? {
        guard let q1 = profile.q1TrainingHistory, let q2 = profile.q2SelfSelect else { return nil }
        return ExperienceResolver.resolve(q1: q1, q2: q2,
                                           onGLP1: profile.healthHistory?.onAntiObesityTherapy ?? false).resolved
    }

    private func generatePlan() {
        guard !isGeneratingPlan,
              let profile, let stage = profile.program?.currentStage else { return }
        let blocks = SessionPlanBuilder.blocks(stage: stage, profile: profile)
        let note = SessionPlanBuilder.projectedCompletionNote(
            frequencyPerWeek: profile.schedule.frequencyPerWeek, stage: stage)
        let renderer = container.pdfRenderer
        isGeneratingPlan = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url = renderer.render(stage: stage, blocks: blocks, completionNote: note)
            DispatchQueue.main.async {
                isGeneratingPlan = false
                if let url { pdfURL = url; showPlan = true }
            }
        }
    }
}
