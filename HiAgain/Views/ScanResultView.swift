import SwiftUI

struct ScanResultView: View {
    let outcome: ScanOutcome
    var onDone: () -> Void = {}

    var body: some View {
        Text("ScanResultView").font(Theme.title(28)).foregroundStyle(Theme.ink)
    }
}

#Preview { ScanResultView(outcome: .unknown) }
