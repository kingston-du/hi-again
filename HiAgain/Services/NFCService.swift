import Foundation
import CoreNFC

/// B4 (Claude). Polls .iso14443 and .iso15693 and returns the first tag's identifier.
final class NFCService: NSObject {
    static let shared = NFCService()

    func readCardUID() async throws -> Data { throw StubError.notImplemented }
}
