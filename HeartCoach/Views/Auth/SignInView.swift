import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var currentNonce = ""

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)
                Text("HeartCoach")
                    .font(.largeTitle.bold())
                Text("Train smarter. Not harder.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    currentNonce = AppleSignInNonceGenerator.generateRawNonce()
                    request.nonce = AppleSignInNonceGenerator.sha256(currentNonce)
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    Task {
                        await authViewModel.signInWithApple(result: result, rawNonce: currentNonce)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .accessibilityIdentifier("signin-apple-button")

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
