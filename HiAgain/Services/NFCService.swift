import Foundation
import CoreNFC

enum NFCError: LocalizedError {
    case unavailable, cancelled, unreadable

    var errorDescription: String? {
        switch self {
        case .unavailable: "This phone can't read cards."
        case .cancelled: nil
        case .unreadable: "Couldn't read that. Hold it near the top of your phone."
        }
    }
}

/// Polls .iso14443 and .iso15693 and returns the first tag's identifier.
final class NFCService: NSObject, NFCTagReaderSessionDelegate {
    static let shared = NFCService()

    private var session: NFCTagReaderSession?
    private var continuation: CheckedContinuation<Data, Error>?

    @MainActor
    func readCardUID() async throws -> Data {
        guard NFCTagReaderSession.readingAvailable else { throw NFCError.unavailable }
        finish(.failure(NFCError.cancelled))  // a previous read that never ended
        session?.invalidate()
        session = nil
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            guard let session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self, queue: .main) else {
                finish(.failure(NFCError.unavailable))
                return
            }
            session.alertMessage = "Hold a card near the top of your phone."
            self.session = session
            session.begin()
        }
    }

    private func finish(_ result: Result<Data, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }

    // MARK: NFCTagReaderSessionDelegate (delivered on the main queue)

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        guard session === self.session else { return }  // a stale session from an earlier read
        let code = (error as? NFCReaderError)?.code
        let cancelled = code == .readerSessionInvalidationErrorUserCanceled
            || code == .readerSessionInvalidationErrorFirstNDEFTagRead
        finish(.failure(cancelled ? NFCError.cancelled : NFCError.unreadable))
        self.session = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard session === self.session, let tag = tags.first else { return }
        session.connect(to: tag) { [weak self] error in
            guard let self, session === self.session else { return }
            if error != nil {
                session.invalidate(errorMessage: "Couldn't read that. Try again.")
                self.finish(.failure(NFCError.unreadable))
                return
            }
            guard let uid = Self.identifier(of: tag), !uid.isEmpty else {
                session.invalidate(errorMessage: "Couldn't read that card.")
                self.finish(.failure(NFCError.unreadable))
                return
            }
            session.alertMessage = "Got it."
            self.finish(.success(uid))
            self.session = nil
            session.invalidate()
        }
    }

    private static func identifier(of tag: NFCTag) -> Data? {
        switch tag {
        case .miFare(let t): t.identifier
        case .iso7816(let t): t.identifier
        case .iso15693(let t): t.identifier
        case .feliCa(let t): t.currentIDm
        @unknown default: nil
        }
    }
}
