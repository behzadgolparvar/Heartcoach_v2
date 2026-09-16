import SwiftUI
import HeartRateCoachCore

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var vm
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(HomeViewModel.self) private var homeViewModel

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
                            Text("Fitness experience").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Experience", selection: $vm.fitnessExperience) {
                                Text("Not set").tag(Optional<FitnessExperience>.none)
                                ForEach(FitnessExperience.allCases, id: \.self) { Text($0.displayName).tag(Optional($0)) }
                            }.pickerStyle(.segmented)
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
        .preferredColorScheme(.dark)
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
