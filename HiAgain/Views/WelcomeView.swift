import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Space.l) {
                Text("WelcomeView").font(Theme.display(28)).foregroundStyle(Theme.ink)
                #if DEBUG
                NavigationLink("Debug scan") { DebugScanView() }
                #endif
            }
        }
    }
}

#Preview { WelcomeView() }
