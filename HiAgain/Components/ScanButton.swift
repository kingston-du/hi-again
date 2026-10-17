import SwiftUI

/// 92 pt red circle floating bottom center, white ID-card icon, "Scan a card" under it.
struct ScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Space.s) {
                ZStack {
                    Circle().fill(Theme.stamp)
                    Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.2).padding(6)
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: 12, y: -10)
                        }
                }
                .frame(width: Theme.scanButtonSize, height: Theme.scanButtonSize)
                .shadow(color: Theme.ink.opacity(0.18), radius: 2, y: 2)
                .shadow(color: Theme.ink.opacity(0.16), radius: 14, y: 14)

                Text("Scan a card").font(Theme.ui(13, weight: .semibold)).foregroundStyle(Theme.ink)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan someone's card")
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Theme.paper.ignoresSafeArea()
        ScanButton {}.padding(.bottom, 20)
    }
}
