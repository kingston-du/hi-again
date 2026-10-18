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
    case instagram, snapchat, linkedin, tiktok, phone, discord, email
    var id: String { rawValue }

    var label: String {
        switch self {
        case .instagram: "Instagram"
        case .snapchat: "Snapchat"
        case .linkedin: "LinkedIn"
        case .tiktok: "TikTok"
        case .phone: "Phone"
        case .discord: "Discord"
        case .email: "Email"
        }
    }

    /// Shown before the value: "@", "in/", or empty for phone/email.
    var prefix: String {
        switch self {
        case .linkedin: "in/"
        case .phone, .email: ""
        default: "@"
        }
    }

    /// Discord has no reliable public profile URL — tap copies the username.
    var copiesOnTap: Bool { self == .discord }

    var accessorySystemName: String {
        copiesOnTap ? "doc.on.doc" : "arrow.up.right"
    }

    func appURL(_ handle: String) -> URL? {
        let h = handle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? handle
        switch self {
        case .instagram: return URL(string: "instagram://user?username=\(h)")
        case .snapchat: return URL(string: "snapchat://add/\(h)")
        case .linkedin: return URL(string: "linkedin://in/\(h)")
        case .tiktok: return URL(string: "snssdk1233://user?unique_id=\(h)")
        case .phone, .discord, .email: return nil
        }
    }

    func webURL(_ handle: String) -> URL? {
        let h = handle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? handle
        switch self {
        case .instagram: return URL(string: "https://instagram.com/\(h)")
        case .snapchat: return URL(string: "https://snapchat.com/add/\(h)")
        case .linkedin: return URL(string: "https://linkedin.com/in/\(h)")
        case .tiktok: return URL(string: "https://tiktok.com/@\(h)")
        case .phone:
            let digits = handle.filter { $0.isNumber || $0 == "+" }
            return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
        case .email:
            let encoded = handle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? handle
            return URL(string: "mailto:\(encoded)")
        case .discord: return nil
        }
    }

    static func handles(of profile: Profile) -> [(Social, String)] {
        [
            (.instagram, profile.instagram),
            (.snapchat, profile.snapchat),
            (.linkedin, profile.linkedin),
            (.tiktok, profile.tiktok),
            (.phone, profile.phone),
            (.discord, profile.discord),
            (.email, profile.email),
        ]
        .compactMap { s, h in h.flatMap { $0.isEmpty ? nil : (s, $0) } }
    }
}

/// Opens the network's app, falls back to the website, or copies Discord.
func openSocial(_ social: Social, handle: String) {
    if social.copiesOnTap {
        UIPasteboard.general.string = handle
        return
    }
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
                Image(systemName: social.accessorySystemName).font(Theme.ui(13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Space.l)
            .frame(height: 48)
            .overlay(RoundedRectangle(cornerRadius: Theme.buttonRadius).strokeBorder(.white, lineWidth: 1.5))
        }
        .accessibilityLabel(social.copiesOnTap
            ? "Copy \(social.label), \(handle)"
            : "Open \(social.label), \(handle)")
    }
}

/// Grouped row version for Person: label, handle, ↗ (or copy for Discord).
struct SocialLinkRow: View {
    let social: Social
    let handle: String

    var body: some View {
        Button { openSocial(social, handle: handle) } label: {
            HStack {
                Text(social.label).font(Theme.ui(17)).foregroundStyle(Theme.ink)
                Spacer()
                Text(social.prefix + handle).font(Theme.ui(17)).foregroundStyle(Theme.muted)
                Image(systemName: social.accessorySystemName)
                    .font(Theme.ui(13, weight: .semibold))
                    .foregroundStyle(Theme.faint)
            }
            .padding(.horizontal, Theme.Space.l)
            .frame(height: Theme.rowHeight)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(social.copiesOnTap
            ? "Copy \(social.label), \(handle)"
            : "Open \(social.label), \(handle)")
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
