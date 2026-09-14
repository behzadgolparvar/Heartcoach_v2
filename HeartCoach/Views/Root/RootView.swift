import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            switch authViewModel.appState {
            case .loading:
                LoadingView()
            case .signedOut:
                SignInView()
            case .onboarding:
                OnboardingContainerView()
            case .main:
                MainTabView()
            case .loadError:
                LoadErrorView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.appState)
        .onAppear { authViewModel.checkAuthState() }
    }
}

/// Shown when the profile couldn't be loaded (network / permissions). Offers a retry
/// so a transient failure never sends an existing user back through onboarding.
private struct LoadErrorView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Couldn't load your data")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(authViewModel.errorMessage ?? "Please check your connection and try again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                Task { await authViewModel.retryLoad() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .accessibilityIdentifier("loaderror-retry")

            Button("Sign Out") { authViewModel.signOut() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("loaderror-signout")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
