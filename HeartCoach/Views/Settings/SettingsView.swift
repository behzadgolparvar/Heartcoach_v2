import SwiftUI
import HeartRateCoachCore

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(HomeViewModel.self) private var homeViewModel
    @Environment(AppContainer.self) private var container
    @State private var pdfURL: URL?
    @State private var showShare = false

    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    SectionHeader("Profile")
                    VStack(alignment: .leading, spacing: 16) {
                        LabelledField("Age", placeholder: "e.g. 32", text: $vm.ageText, keyboardType: .numberPad,
                                      identifier: "settings-age-field") { vm.updatePreview() }
                        LabelledField("Resting HR (bpm)", placeholder: "e.g. 62", text: $vm.rhrText, keyboardType: .numberPad,
                                      identifier: "settings-rhr-field") { vm.updatePreview() }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Gender").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Gender", selection: $vm.gender) {
                                Text("Not set").tag(Optional<Gender>.none)
                                ForEach(Gender.allCases, id: \.self) { Text($0.displayName).tag(Optional($0)) }
                            }.pickerStyle(.menu)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Training history").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Training history", selection: $vm.q1TrainingHistory) {
                                Text("Not set").tag(Optional<TrainingHistory>.none)
                                ForEach(TrainingHistory.allCases, id: \.self) { Text($0.displayName).tag(Optional($0)) }
                            }.pickerStyle(.menu)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Self-rated experience").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Self-rated experience", selection: $vm.q2SelfSelect) {
                                Text("Not set").tag(Optional<FitnessExperience>.none)
                                ForEach(FitnessExperience.allCases, id: \.self) { Text($0.displayName).tag(Optional($0)) }
                            }.pickerStyle(.segmented)
                        }

                        Toggle("On Ozempic / anti-obesity therapy", isOn: $vm.onAntiObesityTherapy)
                            .font(.subheadline).foregroundStyle(.secondary)

                        if let resolved = vm.resolvedExperience {
                            Text("Training level: \(resolved.displayName)")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }

                    SectionHeader("Goals")
                    VStack(spacing: 8) {
                        ForEach(TrainingGoal.allCases, id: \.self) { g in
                            MultiSelectRow(title: g.displayName, value: g, selection: $vm.goals)
                        }
                    }

                    if let zones = vm.previewedZones {
                        SectionHeader("Zone Preview")
                        VStack(spacing: 0) {
                            ForEach([zones.zone1, zones.zone2, zones.zone3, zones.zone4, zones.zone5], id: \.number) { zone in
                                ZoneRowView(zone: zone)
                                if zone.number < 5 { Divider().background(Color.white.opacity(0.1)) }
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let warning = vm.rhrWarning {
                        WarningBanner(message: warning == .belowTypicalRange
                            ? "RHR is below the typical range (40 bpm). Please confirm."
                            : "RHR is above the typical range (100 bpm). Please confirm.")
                    }
                    if let error = vm.fieldError { ErrorBanner(message: error) }
                    if vm.saveSuccess {
                        Label("Saved successfully.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green).font(.subheadline)
                    }

                    SectionHeader("Your Program")
                    VStack(alignment: .leading, spacing: 8) {
                        Button("View my plan (PDF)") { generatePlan() }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(homeViewModel.profile?.program == nil)
                            .accessibilityIdentifier("settings-view-plan")
                        Text("A printable overview of your current stage's sessions.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }

                    Button(vm.isSaving ? "Saving…" : "Save") {
                        if let userID = authViewModel.currentUserID { vm.save(userID: userID) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isSaving)
                    .accessibilityIdentifier("settings-save")

                    Divider().background(Color.white.opacity(0.1))

                    Button("Sign Out", role: .destructive) {
                        vm.signOut()
                        authViewModel.appState = .signedOut
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("settings-sign-out")
                }
                .padding(24)
                .hideKeyboardOnTap()
            }
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .dismissableKeyboard()
        }
        .onAppear {
            if let profile = homeViewModel.profile { vm.populate(from: profile) }
        }
        .alert("A note on your training start", isPresented: $vm.showOzempicInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Research shows that combining exercise with GLP-1 medications like Ozempic is linked to greater fat loss and better weight-loss maintenance after stopping the medication.\n\nYour training will start at a Beginner level to build a strong, sustainable foundation alongside your medication.")
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShare) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
    }

    private func generatePlan() {
        guard let profile = homeViewModel.profile, let stage = profile.program?.currentStage else { return }
        let rows = SessionPlanBuilder.plan(stage: stage, profile: profile)
        let note = SessionPlanBuilder.projectedCompletionNote(
            frequencyPerWeek: profile.schedule.frequencyPerWeek, stage: stage)
        if let url = container.pdfRenderer.render(stage: stage, rows: rows, completionNote: note) {
            pdfURL = url
            showShare = true
        }
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { Text(title).font(.headline).foregroundStyle(.white) }
}

private struct LabelledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let identifier: String
    let onChange: () -> Void

    init(_ label: String, placeholder: String, text: Binding<String>,
         keyboardType: UIKeyboardType = .default, identifier: String, onChange: @escaping () -> Void) {
        self.label = label; self.placeholder = placeholder; self._text = text
        self.keyboardType = keyboardType; self.identifier = identifier; self.onChange = onChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(identifier)
                .onChange(of: text) { _, _ in onChange() }
        }
    }
}
