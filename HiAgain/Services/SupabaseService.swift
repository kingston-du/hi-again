import Foundation
import Supabase

/// B3 (Codex) fills in the internals. Signatures are the contract in docs/PLAN.md Part 3.
@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    @Published var session: Session?

    private init() {}

    func signInWithApple(idToken: String, nonce: String) async throws { throw StubError.notImplemented }
    func signOut() async throws { throw StubError.notImplemented }
    func myProfile() async throws -> Profile? { throw StubError.notImplemented }
    func saveProfile(_ profile: Profile) async throws { throw StubError.notImplemented }
    func claimCard(hash: String) async throws -> ClaimResult { throw StubError.notImplemented }
    func unlinkCard() async throws { throw StubError.notImplemented }
    func scanCard(hash: String, place: Place?) async throws -> ScanOutcome { throw StubError.notImplemented }
    func people() async throws -> [Person] { throw StubError.notImplemented }
    func updateNote(meetingId: UUID, text: String) async throws { throw StubError.notImplemented }
    func removePerson(id: UUID) async throws { throw StubError.notImplemented }
}

enum StubError: Error { case notImplemented }
