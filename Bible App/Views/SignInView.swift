import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)
            Text("Sign in to your\nAccount")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            VStack(spacing: 12) {
                Button(action: { Task { await signInGoogle() } }) {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle")
                            .font(.title2)
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Placeholders for future email/password
                VStack(spacing: 10) {
                    TextField("Email", text: .constant(""))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    SecureField("Password", text: .constant(""))
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .opacity(0.8)
            }
            .padding(.horizontal, 20)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signInGoogle() async {
        do {
            try await auth.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


