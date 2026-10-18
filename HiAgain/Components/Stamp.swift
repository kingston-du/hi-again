import SwiftUI

/// A round rubber stamp: place around the ring, MET / date / time in the middle (date only once).
struct Stamp: View {
    var place: String?
    var date: Date
    var diameter: CGFloat = 116
    var color: Color = Theme.stamp
    var rotation: Double = -12

    var body: some View {
        let s = diameter / 100
        ZStack {
            Circle().strokeBorder(color, lineWidth: 2.6 * s / 1.16)
            Circle().stroke(color, lineWidth: 1.2 * s / 1.16).frame(width: diameter * 0.62, height: diameter * 0.62)
            RingText(text: ringText, radius: diameter * 0.39, fontSize: 9 * s, color: color)
            VStack(spacing: 0) {
                Text("MET").font(Theme.stampText(15 * s)).tracking(1)
                Text(date.formatted(.dateTime.month(.abbreviated).day()).uppercased()).font(Theme.stampText(10 * s))
                Text(date.formatted(date: .omitted, time: .shortened).uppercased()).font(Theme.stampText(8 * s))
            }
            .foregroundStyle(color)
        }
        .frame(width: diameter, height: diameter)
        .opacity(0.92)
        .rotationEffect(.degrees(rotation))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Met \(place.map { "at \($0), " } ?? "")\(date.formatted(date: .abbreviated, time: .shortened))")
    }

    private var ringText: String {
        let where_ = (place?.isEmpty == false ? place! : "HI AGAIN").uppercased()
        let text = "\(where_) • "
        return text.count < 24 ? text + text : text
    }
}

/// Text laid out clockwise around a circle, starting at the top.
private struct RingText: View {
    let text: String
    let radius: CGFloat
    let fontSize: CGFloat
    let color: Color

    var body: some View {
        let chars = Array(text)
        // Spread the characters evenly around the whole ring.
        let step = 360.0 / Double(max(chars.count, 1))
        let start = 0.0
        ZStack {
            ForEach(Array(chars.enumerated()), id: \.offset) { i, ch in
                Text(String(ch))
                    .font(Theme.stampText(fontSize))
                    .foregroundStyle(color)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(start + step * Double(i)))
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        Stamp(place: "HUB", date: .now)
        Stamp(place: "Paul G. Allen Center", date: .now, diameter: 92, rotation: 10)
        Stamp(place: nil, date: .now, diameter: 116, color: .white).padding().background(Theme.stamp)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.paper)
}
