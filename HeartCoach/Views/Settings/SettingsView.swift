import SwiftUI
import AVFoundation

/// App settings (presented from Profile's gear): account, preferences, about.
/// Profile data / onboarding answers live in `ProfileView`, not here.
struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    /// Persisted voice preference; applied to the live session when WorkoutView appears.
    @AppStorage("voiceCoachingMuted") private var voiceMuted = false
    /// "" = automatic (best available); otherwise an AVSpeechSynthesisVoice identifier.
    @AppStorage("preferredVoiceId") private var voiceId = ""

    private var englishVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "en-US" }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Account
                    VStack(alignment: .leading, spacing: 12) {
                        title("Account")
                        if let email = authViewModel.currentUserEmail {
                            HStack {
                                Text("Email").foregroundStyle(.secondary)
                                Spacer(minLength: 16)
                                Text(email).foregroundStyle(.white).multilineTextAlignment(.trailing)
                            }
                            .font(.subheadline)
                        }
                        Button(authViewModel.isLoading ? "Sending…" : "Change password") {
                            Task { await authViewModel.sendPasswordResetToCurrentUser() }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(authViewModel.isLoading)
                        Text("We'll email you a link to set a new password.")
                            .font(.footnote).foregroundStyle(.secondary)

                        if let info = authViewModel.infoMessage {
                            Text(info).font(.footnote).foregroundStyle(.green)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let error = authViewModel.errorMessage {
                            Text(error).font(.footnote).foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Preferences
                    VStack(alignment: .leading, spacing: 8) {
                        title("Preferences")
                        Toggle("Voice coaching", isOn: Binding(
                            get: { !voiceMuted }, set: { voiceMuted = !$0 }))
                            .tint(.red)
                        Text("Spoken cues during workouts. Safety alerts always play.")
                            .font(.footnote).foregroundStyle(.secondary)

                        HStack {
                            Text("Coach voice").foregroundStyle(.white)
                            Spacer()
                            Picker("Coach voice", selection: $voiceId) {
                                Text("Automatic").tag("")
                                ForEach(englishVoices, id: \.identifier) { v in
                                    Text(voiceLabel(v)).tag(v.identifier)
                                }
                            }
                            .pickerStyle(.menu).tint(.secondary)
                        }
                        .font(.subheadline)
                        .onChange(of: voiceId) { _, newValue in
                            container.voiceFeedbackService.voiceIdentifier = newValue.isEmpty ? nil : newValue
                        }
                    }

                    // About
                    VStack(alignment: .leading, spacing: 8) {
                        title("About")
                        HStack {
                            Text("Version").foregroundStyle(.secondary)
                            Spacer()
                            Text(appVersion).foregroundStyle(.white)
                        }
                        .font(.subheadline)
                    }

                    Divider().background(Color.white.opacity(0.1))

                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("settings-sign-out")
                }
                .padding(24)
            }
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { authViewModel.infoMessage = nil; authViewModel.errorMessage = nil }
    }

    private func title(_ t: String) -> some View { Text(t).font(.headline).foregroundStyle(.white) }

    private func voiceLabel(_ v: AVSpeechSynthesisVoice) -> String {
        switch v.quality {
        case .premium: return "\(v.name) (Premium)"
        case .enhanced: return "\(v.name) (Enhanced)"
        default: return v.name
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}
