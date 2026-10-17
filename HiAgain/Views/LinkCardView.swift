import SwiftUI

struct LinkCardView: View {
    var onDone: () -> Void = {}

    var body: some View {
        Text("LinkCardView").font(Theme.display(28)).foregroundStyle(Theme.ink)
    }
}

#Preview { LinkCardView() }
