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

                    // Profile section
                    SectionHeader("Profile")

                    VStack(alignment: .leading, spacing: 16) {
                        LabelledField("Age", placeholder: "e.g. 32", text: $vm.ageText, keyboardType: .numberPad,
                                      identifier: "settings-age-field") { vm.updatePreview() }
                        LabelledField("Resting HR (bpm)", placeholder: "e.g. 62", text: $vm.rhrText, keyboardType: .numberPad,
                                      identifier: "settings-rhr-field") { vm.updatePreview() }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sex").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Sex", selection: $vm.sex) {
                                Text("Not specified").tag(Optional<Sex>.none)
                                Text("Male").tag(Optional<Sex>.some(.male))
                                Text("Female").tag(Optional<Sex>.some(.female))
                                Text("Other").tag(Optional<Sex>.some(.other))
                            }.pickerStyle(.menu)
                        }

                        LabelledField("Weight (kg)", placeholder: "e.g. 75", text: $vm.weightText, keyboardType: .decimalPad,
                                      identifier: "settings-weight-field") {}
                    }

                    // Training section
                    SectionHeader("Training")

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Goal").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Goal", selection: $vm.goal) {
                                Text("Fat Burn").tag(Goal.fatBurn)
                                Text("Endurance").tag(Goal.endurance)
                            }.pickerStyle(.segmented)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Workout").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Workout", selection: $vm.preferredWorkout) {
                                Text("Continuous").tag(WorkoutType.continuous)
                                Text("HIIT").tag(WorkoutType.hiit)
                                Text("Fartlek").tag(WorkoutType.fartlek)
                            }.pickerStyle(.segmented)
                        }
                    }

                    // Zone preview
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

                    if let error = vm.fieldError {
                        ErrorBanner(message: error)
                    }

                    if vm.saveSuccess {
                        Label("Saved successfully.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green).font(.subheadline)
                    }

                    // Save
                    Button(vm.isSaving ? "Saving…" : "Save") {
                        if let userID = authViewModel.authService.currentUserID {
                            vm.save(userID: userID)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isSaving)
                    .accessibilityIdentifier("settings-save")

                    Divider().background(Color.white.opacity(0.1))

                    // Sign Out
                    Button("Sign Out", role: .destructive) {
                        vm.signOut()
                        authViewModel.appState = .signedOut
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("settings-sign-out")
                }
                .padding(24)
            }
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let profile = homeViewModel.profile {
                vm.populate(from: profile)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title).font(.headline).foregroundStyle(.white)
    }
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
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.identifier = identifier
        self.onChange = onChange
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
