import SwiftUI

/// 54 pt, radius 14, ink fill, white SF Semibold 17. `inverted` is white with ink text (on the red scan screen).
struct PrimaryButtonStyle: ButtonStyle {
    var inverted = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.ui(17, weight: .semibold))
            .foregroundStyle(inverted ? Theme.ink : .white)
            .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight)
            .background(inverted ? Color.white : Theme.ink, in: RoundedRectangle(cornerRadius: Theme.buttonRadius))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.35)
    }
}

/// Same size as primary; white with a rule border and ink text.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.ui(17, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.buttonRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.buttonRadius).strokeBorder(Theme.rule, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var primaryInverted: PrimaryButtonStyle { PrimaryButtonStyle(inverted: true) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

enum Social: String, CaseIterable, Identifiable {
    case instagram, snapchat, linkedin
    var id: String { rawValue }

    var label: String {
        switch self { case .instagram: "Instagram"; case .snapchat: "Snapchat"; case .linkedin: "LinkedIn" }
    }
    /// Shown before the handle: "@" or "in/".
    var prefix: String { self == .linkedin ? "in/" : "@" }

    func appURL(_ handle: String) -> URL? {
        switch self {
        case .instagram: URL(string: "instagram://user?username=\(handle)")
        case .snapchat: URL(string: "snapchat://add/\(handle)")
        case .linkedin: URL(string: "linkedin://in/\(handle)")
        }
    }

    func webURL(_ handle: String) -> URL? {
        switch self {
        case .instagram: URL(string: "https://instagram.com/\(handle)")
        case .snapchat: URL(string: "https://snapchat.com/add/\(handle)")
        case .linkedin: URL(string: "https://linkedin.com/in/\(handle)")
        }
    }

    static func handles(of profile: Profile) -> [(Social, String)] {
        [(.instagram, profile.instagram), (.snapchat, profile.snapchat), (.linkedin, profile.linkedin)]
            .compactMap { s, h in h.flatMap { $0.isEmpty ? nil : (s, $0) } }
    }
}

/// Opens the network's app, falling back to its website.
func openSocial(_ social: Social, handle: String) {
    let handle = handle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? handle
    guard let web = social.webURL(handle) else { return }
    if let app = social.appURL(handle) {
        UIApplication.shared.open(app) { ok in if !ok { UIApplication.shared.open(web) } }
    } else {
        UIApplication.shared.open(web)
    }
}

/// White 1.5 pt outline button with label and handle, for the red scan screen.
struct SocialButton: View {
    let social: Social
    let handle: String

    var body: some View {
        Button { openSocial(social, handle: handle) } label: {
            HStack {
                Text(social.label).font(Theme.ui(16, weight: .semibold))
                Spacer()
                Text(social.prefix + handle).font(Theme.ui(15)).opacity(0.85)
                Image(systemName: "arrow.up.right").font(Theme.ui(13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Space.l)
            .frame(height: 48)
            .overlay(RoundedRectangle(cornerRadius: Theme.buttonRadius).strokeBorder(.white, lineWidth: 1.5))
        }
        .accessibilityLabel("Open \(social.label), \(handle)")
    }
}

/// Grouped row version for Person: label, handle, ↗.
struct SocialLinkRow: View {
    let social: Social
    let handle: String

    var body: some View {
        Button { openSocial(social, handle: handle) } label: {
            HStack {
                Text(social.label).font(Theme.ui(17)).foregroundStyle(Theme.ink)
                Spacer()
                Text(social.prefix + handle).font(Theme.ui(17)).foregroundStyle(Theme.muted)
                Image(systemName: "arrow.up.right").font(Theme.ui(13, weight: .semibold)).foregroundStyle(Theme.faint)
            }
            .padding(.horizontal, Theme.Space.l)
            .frame(height: Theme.rowHeight)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        Button("Next") {}.buttonStyle(.primary)
        Button("Next") {}.buttonStyle(.primary).disabled(true)
        Button("Skip for now") {}.buttonStyle(.secondary)
        VStack(spacing: 8) {
            SocialButton(social: .instagram, handle: "maya.codes")
            Button("Done") {}.buttonStyle(.primaryInverted)
        }
        .padding().background(Theme.stamp)
        VStack(spacing: 0) {
            SocialLinkRow(social: .instagram, handle: "maya.codes")
            Divider().overlay(Theme.ruleSoft)
            SocialLinkRow(social: .linkedin, handle: "mayalee")
        }
        .groupBox()
    }
    .padding()
    .background(Theme.paper)
}
