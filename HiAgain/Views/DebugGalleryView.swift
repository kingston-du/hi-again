#if DEBUG
import SwiftUI

/// Every component on paper, for eyeballing. Launch with `-gallery` to open it directly.
struct DebugGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                (Text("hi again").font(Theme.wordmark()) + Text(".").font(Theme.wordmark()).foregroundColor(Theme.stamp))
                Text("People").font(Theme.title()).tracking(Theme.titleTracking)
                StampedSticker(firstName: "Maya", color: .red, place: "HUB", date: .now, tilt: -3)
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
extension ScanResult {
    static let debugMet = ScanResult(
        outcome: .met(Profile(id: UUID(), firstName: "Maya", lastName: "Lee", badgeColor: .blue,
                              instagram: "maya.codes", snapchat: nil, linkedin: "mayalee"),
                      meetingId: UUID(), timesMet: 1),
        place: Place(name: "HUB", lat: 0, lng: 0), at: .now)
}
#endif
