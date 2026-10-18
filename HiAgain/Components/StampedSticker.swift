import SwiftUI

private let stampedStickerDiameter: CGFloat = 116
/// Hang past the sticker’s SE corner — most of the stamp sits on the white name panel.
private let stampedStickerHangX: CGFloat = 40
private let stampedStickerHangY: CGFloat = 48

/// Large HELLO sticker with a stamp lightly kissing the bottom-right corner.
/// Padding reserves the stamp overhang so sibling text never sits under the ink.
struct StampedSticker<StampChrome: View>: View {
    let firstName: String
    let color: BadgeColor
    var place: String?
    var date: Date
    var stampColor: Color
    var tilt: Double
    var stampRotation: Double
    private let stampChrome: (Stamp) -> StampChrome

    init(
        firstName: String,
        color: BadgeColor,
        place: String?,
        date: Date = .now,
        stampColor: Color = Theme.stamp,
        tilt: Double = -3,
        stampRotation: Double = 10,
        @ViewBuilder stampChrome: @escaping (Stamp) -> StampChrome
    ) {
        self.firstName = firstName
        self.color = color
        self.place = place
        self.date = date
        self.stampColor = stampColor
        self.tilt = tilt
        self.stampRotation = stampRotation
        self.stampChrome = stampChrome
    }

    var body: some View {
        let stamp = Stamp(
            place: place,
            date: date,
            diameter: stampedStickerDiameter,
            color: stampColor,
            rotation: stampRotation
        )
        // Overlay + compositingGroup: stamp paints above sticker & its soft shadow.
        // Multiply on ink stamps so red-on-red still reads as stamped on top (white scan stamps stay normal).
        Sticker(firstName: firstName, color: color, size: .large, tilt: tilt)
            .compositingGroup()
            .overlay(alignment: .bottomTrailing) {
                stampChrome(stamp)
                    .blendMode(stampColor == .white ? .normal : .multiply)
                    .offset(x: stampedStickerHangX, y: stampedStickerHangY)
            }
            .padding(.trailing, stampedStickerHangX)
            .padding(.bottom, stampedStickerHangY)
    }
}

extension StampedSticker where StampChrome == Stamp {
    init(
        firstName: String,
        color: BadgeColor,
        place: String?,
        date: Date = .now,
        stampColor: Color = Theme.stamp,
        tilt: Double = -3,
        stampRotation: Double = 10
    ) {
        self.init(
            firstName: firstName,
            color: color,
            place: place,
            date: date,
            stampColor: stampColor,
            tilt: tilt,
            stampRotation: stampRotation,
            stampChrome: { $0 }
        )
    }
}

#Preview("Paper") {
    StampedSticker(firstName: "Maya", color: .red, place: "HUB", date: .now, tilt: -4, stampRotation: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
}

#Preview("Scan red") {
    StampedSticker(
        firstName: "Maya",
        color: .black,
        place: "HUB",
        date: .now,
        stampColor: .white,
        tilt: -3,
        stampRotation: 12
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.stamp)
}
