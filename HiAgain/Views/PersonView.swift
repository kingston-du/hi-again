import SwiftUI

struct PersonView: View {
    let person: Person

    var body: some View {
        Text(person.profile.firstName).font(Theme.display(28)).foregroundStyle(Theme.ink)
    }
}
