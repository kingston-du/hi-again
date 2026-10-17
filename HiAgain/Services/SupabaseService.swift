import Foundation
import Supabase

/// Part 3 contract. Client from Info.plist `SUPABASE_URL` / `SUPABASE_ANON_KEY`; session survives restart via auth storage.
@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    @Published var session: Session?

    private let client: SupabaseClient
    private var authListenTask: Task<Void, Never>?

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString), !urlString.isEmpty,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !anonKey.isEmpty
        else {
            preconditionFailure("Missing SUPABASE_URL or SUPABASE_ANON_KEY in Info.plist (Secrets.xcconfig).")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        authListenTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in self.client.auth.authStateChanges {
                guard [.initialSession, .signedIn, .signedOut, .tokenRefreshed, .userUpdated]
                    .contains(event) else { continue }
                self.session = session
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func myProfile() async throws -> Profile? {
        guard let userId = session?.user.id else { return nil }
        return try await client.from("profiles")
            .select()
            .eq("id", value: userId)
            .maybeSingle()
            .execute()
            .value
    }

    func saveProfile(_ profile: Profile) async throws {
        try await client.from("profiles")
            .upsert(profile)
            .execute()
    }

    func claimCard(hash: String) async throws -> ClaimResult {
        let raw: String = try await client.rpc("claim_card", params: ClaimHashParams(p_hash: hash))
            .execute()
            .value
        guard let result = ClaimResult(rawValue: raw) else {
            throw SupabaseServiceError.unexpectedClaimResult(raw)
        }
        return result
    }

    func unlinkCard() async throws {
        try await client.rpc("unlink_card").execute()
    }

    func scanCard(hash: String, place: Place?) async throws -> ScanOutcome {
        let response: ScanRPCResponse = try await client.rpc(
            "scan_card",
            params: ScanCardParams(
                p_hash: hash,
                p_lat: place?.lat,
                p_lng: place?.lng,
                p_place: place?.name
            )
        )
        .execute()
        .value

        switch response.status {
        case "unknown":
            return .unknown
        case "self":
            return .ownCard
        case "met":
            guard
                let profile = response.profile,
                let meetingId = response.meetingId,
                let timesMet = response.timesMet
            else {
                throw SupabaseServiceError.malformedScanResponse
            }
            return .met(profile, meetingId: meetingId, timesMet: timesMet)
        default:
            throw SupabaseServiceError.unexpectedScanStatus(response.status)
        }
    }

    func people() async throws -> [Person] {
        let meetings: [Meeting] = try await client.from("meetings")
            .select()
            .order("met_at", ascending: false)
            .execute()
            .value

        guard !meetings.isEmpty else { return [] }

        let otherIds = Array(Set(meetings.map(\.otherId)))
        let profiles: [Profile] = try await client.from("profiles")
            .select()
            .in("id", values: otherIds)
            .execute()
            .value

        let byId = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
        var grouped: [UUID: [Meeting]] = [:]
        for meeting in meetings {
            grouped[meeting.otherId, default: []].append(meeting)
        }

        return otherIds.compactMap { id -> Person? in
            guard let profile = byId[id], let personMeetings = grouped[id], !personMeetings.isEmpty else {
                return nil
            }
            return Person(profile: profile, meetings: personMeetings)
        }
        .sorted { $0.lastMet > $1.lastMet }
    }

    func updateNote(meetingId: UUID, text: String) async throws {
        try await client.from("meetings")
            .update(NoteUpdate(note: text))
            .eq("id", value: meetingId)
            .execute()
    }

    func removePerson(id: UUID) async throws {
        try await client.from("meetings")
            .delete()
            .eq("other_id", value: id)
            .execute()
    }
}

// MARK: - Private payloads

private struct ClaimHashParams: Encodable {
    let p_hash: String
}

private struct ScanCardParams: Encodable {
    let p_hash: String
    let p_lat: Double?
    let p_lng: Double?
    let p_place: String?
}

private struct NoteUpdate: Encodable {
    let note: String
}

private struct ScanRPCResponse: Decodable {
    let status: String
    let meetingId: UUID?
    let timesMet: Int?
    let profile: Profile?

    enum CodingKeys: String, CodingKey {
        case status
        case meetingId = "meeting_id"
        case timesMet = "times_met"
        case profile
    }
}

enum SupabaseServiceError: Error {
    case unexpectedClaimResult(String)
    case unexpectedScanStatus(String)
    case malformedScanResponse
}
