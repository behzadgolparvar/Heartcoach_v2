import SwiftUI

struct SignInView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        @Bindable var vm = authViewModel

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

            VStack(spacing: 12) {
                TextField("Email", text: $vm.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                SecureField("Password", text: $vm.password)
                    .textContentType(vm.isSignUpMode ? .newPassword : .password)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    Task { await authViewModel.submitAuth() }
                } label: {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Text(authViewModel.isSignUpMode ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(authViewModel.isLoading)

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    authViewModel.isSignUpMode.toggle()
                    authViewModel.errorMessage = nil
                } label: {
                    Text(authViewModel.isSignUpMode
                         ? "Already have an account? Sign In"
                         : "New here? Create an account")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
