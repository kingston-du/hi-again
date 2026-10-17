import Foundation

struct Person: Identifiable, Hashable {          // built on the client: one per other_id
    let profile: Profile; let meetings: [Meeting] // newest first
    var id: UUID { profile.id }; var lastMet: Date { meetings[0].metAt }
}
