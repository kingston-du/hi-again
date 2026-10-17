#if DEBUG
import SwiftUI

/// Every component on paper, for eyeballing. Launch with `-gallery` to open it directly.
struct DebugGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                (Text("hi again").font(Theme.wordmark()) + Text(".").font(Theme.wordmark()).foregroundColor(Theme.stamp))
                Text("People").font(Theme.title()).tracking(Theme.titleTracking)
                ZStack(alignment: .bottomTrailing) {
                    Sticker(firstName: "Maya", color: .red, size: .large, tilt: -3)
                    Stamp(place: "HUB", date: .now).offset(x: 30, y: 30)
                }
                .padding(.bottom, 30)
                HStack { ForEach(BadgeColor.allCases, id: \.self) { Sticker(firstName: "Maya", color: $0, size: .row) } }
                Sticker(firstName: "Kingston", color: .yellow, size: .medium)
                Button("Next") {}.buttonStyle(.primary)
                Button("Skip for now") {}.buttonStyle(.secondary)
                VStack(spacing: 8) {
                    Stamp(place: "Paul G. Allen Center", date: .now, color: .white, rotation: 8)
                    SocialButton(social: .instagram, handle: "maya.codes")
                    Button("Done") {}.buttonStyle(.primaryInverted)
                }
                .padding().background(Theme.stamp)
                ScanButton {}.frame(maxWidth: .infinity)
            }
            .padding(Theme.Space.l)
        }
        .background(Theme.paper)
    }
}
#endif
