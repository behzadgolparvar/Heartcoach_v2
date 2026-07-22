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
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.appState)
        .onAppear { authViewModel.checkAuthState() }
    }
}
