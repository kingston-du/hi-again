import Foundation

struct Meeting: Codable, Identifiable, Hashable {
    let id: UUID; let ownerId: UUID; let otherId: UUID; let metAt: Date
    var lat: Double?; var lng: Double?; var placeName: String?; var note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case otherId = "other_id"
        case metAt = "met_at"
        case lat, lng
        case placeName = "place_name"
        case note
    }
}
