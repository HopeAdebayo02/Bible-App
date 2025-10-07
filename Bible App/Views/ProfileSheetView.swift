import SwiftUI

struct ProfileSheetView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var appearance: AppearanceService
    @StateObject private var translation = TranslationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Circle().fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(Text(avatarText()).font(.headline))
                    VStack(alignment: .leading) {
                        Text(primaryName()).font(.headline)
                        Text(secondarySubtitle()).font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { appearance.toggle() }) {
                        Image(systemName: appearance.isDarkMode ? "moon.fill" : "moon")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(appearance.isDarkMode ? .primary : .secondary)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }

            Section("Translation") {
                Picker("Version", selection: $translation.version) {
                    ForEach(translation.available, id: \.self) { v in
                        Text(v).tag(v)
                    }
                }
            }

            if auth.isSignedIn == false {
                Section("Account") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sign in (optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Sign in with Google to sync bookmarks and settings. You can continue as a guest.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Button(action: signInWithGoogle) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text("Sign in with Google")
                        }
                    }
                }
            } else {
                Section("Account") {
                    Button(role: .destructive, action: signOut) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }

            if let errorMessage { Section { Text(errorMessage).foregroundColor(.red) } }
        }
        .navigationTitle("Profile")
    }

    private func signOut() {
        Task {
            await auth.signOut()
            dismiss()
        }
    }

    private func initials(_ email: String) -> String {
        let base = email.split(separator: "@").first ?? Substring("")
        let parts = base.split(separator: ".")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)) }
        return String(base.prefix(2)).uppercased()
    }

    private func displayName(_ email: String) -> String {
        String(email.split(separator: "@").first ?? "User")
    }

    private func avatarText() -> String {
        auth.isSignedIn ? initials(auth.userEmail) : "G"
    }

    private func primaryName() -> String {
        auth.isSignedIn ? displayName(auth.userEmail) : "Guest"
    }

    private func secondarySubtitle() -> String {
        auth.isSignedIn ? auth.userEmail : "Not signed in"
    }

    private func signInWithGoogle() {
        Task {
            do {
                try await auth.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}


