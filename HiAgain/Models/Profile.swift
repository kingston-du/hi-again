import Foundation

enum BadgeColor: String, Codable, CaseIterable { case red, blue, green, yellow, pink, black }

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String?
    var badgeColor: BadgeColor
    var bio: String? = nil
    var instagram: String?
    var snapchat: String?
    var linkedin: String?
    var tiktok: String? = nil
    var phone: String? = nil
    var discord: String? = nil
    var email: String? = nil
    var slug: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case badgeColor = "badge_color"
        case bio
        case instagram, snapchat, linkedin, tiktok, phone, discord, email, slug
    }
}
