import SwiftUI

struct MakeBadgeView: View {
    var onSaved: (Profile) -> Void = { _ in }

    var body: some View {
        Text("MakeBadgeView").font(Theme.title(28)).foregroundStyle(Theme.ink)
    }
}

#Preview { MakeBadgeView() }
