import Foundation
import CryptoKit

/// card_hash = SHA-256 hex of (CARD_SALT + card UID as hex). The raw UID never leaves the phone.
enum CardHasher {
    static func hash(_ uid: Data) -> String {
        let salt = Bundle.main.object(forInfoDictionaryKey: "CARD_SALT") as? String ?? ""
        let uidHex = uid.map { String(format: "%02x", $0) }.joined()
        let digest = SHA256.hash(data: Data((salt + uidHex).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func shortCode(_ hash: String) -> String { String(hash.prefix(4)).uppercased() }
}
