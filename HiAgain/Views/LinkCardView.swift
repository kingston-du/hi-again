import SwiftUI

struct LinkCardView: View {
    var onDone: () -> Void = {}

    var body: some View {
        Text("LinkCardView").font(Theme.title(28)).foregroundStyle(Theme.ink)
    }
}

#Preview { LinkCardView() }
