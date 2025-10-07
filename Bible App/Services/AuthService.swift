import Foundation
import Supabase
import Combine

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var userEmail: String = ""
    @Published private(set) var userId: String? = nil

    private let client: SupabaseClient = SupabaseManager.shared.client
    private var cancellables: Set<AnyCancellable> = []

    private init() {
        Task { await refreshState() }
        // We'll refresh state explicitly after callbacks to avoid concurrency issues.
    }

    func signInWithGoogle() async throws {
        let redirect = URL(string: "bibleapp://auth-callback")!
        _ = try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: redirect
        )
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            apply(session: nil)
        } catch { }
    }

    func refreshState() async {
        do {
            let s = try await client.auth.session
            apply(session: s)
        } catch {
            apply(session: nil)
        }
    }

    private func apply(session: Session?) {
        isSignedIn = (session != nil)
        userEmail = session?.user.email ?? ""
        if let anyId = session?.user.id {
            // Supabase User.id may be UUID or String depending on SDK; normalize to String
            userId = String(describing: anyId)
        } else {
            userId = nil
        }
    }
}


