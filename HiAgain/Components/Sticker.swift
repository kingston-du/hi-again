import SwiftUI

/// A "HELLO my name is" sticker in the person's color, with the first name in marker.
struct Sticker: View {
    enum Size {
        case row, medium, large
        var width: CGFloat { switch self { case .row: 46; case .medium: 260; case .large: 300 } }
        var height: CGFloat { (width / 1.53).rounded() }
        var radius: CGFloat { self == .row ? 5 : 12 }
    }

    let firstName: String
    let color: BadgeColor
    var size: Size = .large
    var tilt: Double = 0

    var body: some View {
        let w = size.width, h = size.height
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: size.radius).fill(Theme.badge(color))
            if size == .row {
                panel(text: String(firstName.prefix(1)).uppercased(), fontSize: 18)
                    .padding(.horizontal, 4).padding(.bottom, 4).padding(.top, 9)
            } else {
                VStack(spacing: 0) {
                    Text("HELLO")
                        .font(Theme.hello(w * 0.12)).tracking(2)
                        .foregroundStyle(Theme.onBadge(color))
                        .padding(.top, h * 0.07)
                    Text("my name is")
                        .font(Theme.nameIs(w * 0.043))
                        .foregroundStyle(Theme.onBadge(color))
                        .padding(.bottom, h * 0.05)
                    panel(text: firstName, fontSize: w * 0.24)
                        .padding(.horizontal, 8).padding(.bottom, 12)
                }
            }
        }
        .frame(width: w, height: h)
        .stickerShadow()
        .rotationEffect(.degrees(tilt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hello, my name is \(firstName)")
    }

    private func panel(text: String, fontSize: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 5).fill(Theme.surface)
            .overlay(
                Text(text.isEmpty ? " " : text)
                    .font(Theme.marker(fontSize))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.4)
                    .padding(.horizontal, 6)
            )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 28) {
            Sticker(firstName: "Maya", color: .red, size: .large, tilt: -3)
            Sticker(firstName: "Kingston", color: .blue, size: .medium)
            HStack {
                ForEach(BadgeColor.allCases, id: \.self) { Sticker(firstName: "Maya", color: $0, size: .row) }
            }
            ForEach([BadgeColor.green, .yellow, .pink, .black], id: \.self) {
                Sticker(firstName: "Alexandria", color: $0, size: .medium)
            }
        }
        .padding(.vertical, 40).frame(maxWidth: .infinity)
    }
    .background(Theme.paper)
}
