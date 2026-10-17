import SwiftUI

/// Editable badge fields. Make your badge uses it, and so does Edit badge in Me.
struct BadgeDraft: Equatable {
    var firstName = ""
    var lastName = ""
    var color: BadgeColor = .red
    var instagram = ""
    var snapchat = ""
    var linkedin = ""

    init() {}

    init(_ p: Profile) {
        firstName = p.firstName; lastName = p.lastName ?? ""; color = p.badgeColor
        instagram = p.instagram ?? ""; snapchat = p.snapchat ?? ""; linkedin = p.linkedin ?? ""
    }

    var isValid: Bool {
        !clean(firstName).isEmpty && ![instagram, snapchat, linkedin].allSatisfy { handle($0) == nil }
    }

    func profile(id: UUID) -> Profile {
        Profile(id: id, firstName: clean(firstName), lastName: clean(lastName).isEmpty ? nil : clean(lastName),
                badgeColor: color, instagram: handle(instagram), snapchat: handle(snapchat), linkedin: handle(linkedin))
    }

    private func clean(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Strips "@", "in/" and URL prefixes; nil if empty.
    private func handle(_ s: String) -> String? {
        var h = clean(s)
        for prefix in ["https://", "http://", "www.", "instagram.com/", "snapchat.com/add/", "linkedin.com/in/", "@", "in/"] where h.lowercased().hasPrefix(prefix) {
            h = String(h.dropFirst(prefix.count))
        }
        h = h.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        return h.isEmpty ? nil : h
    }
}

/// Live sticker preview, color swatches, names and socials.
struct BadgeFields: View {
    @Binding var draft: BadgeDraft

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            Sticker(firstName: draft.firstName.isEmpty ? "Your name" : draft.firstName, color: draft.color, size: .medium)
                .frame(maxWidth: .infinity)
                .animation(Theme.drop, value: draft.color)

            HStack(spacing: Theme.Space.m) {
                ForEach(BadgeColor.allCases, id: \.self) { c in
                    Button { draft.color = c } label: {
                        RoundedRectangle(cornerRadius: 8).fill(Theme.badge(c))
                            .frame(width: 40, height: 40)
                            .padding(3)
                            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(draft.color == c ? Theme.ink : .clear, lineWidth: 2))
                    }
                    .accessibilityLabel(c.rawValue.capitalized)
                    .accessibilityAddTraits(draft.color == c ? .isSelected : [])
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 0) {
                field("First name", text: $draft.firstName).textContentType(.givenName)
                divider
                field("Last name", text: $draft.lastName).textContentType(.familyName)
            }
            .groupBox()

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                VStack(spacing: 0) {
                    socialField(.instagram, text: $draft.instagram)
                    divider
                    socialField(.snapchat, text: $draft.snapchat)
                    divider
                    socialField(.linkedin, text: $draft.linkedin)
                }
                .groupBox()
                Text("At least one").font(Theme.ui(13)).foregroundStyle(Theme.muted).padding(.leading, Theme.Space.l)
            }
        }
    }

    private var divider: some View { Rectangle().fill(Theme.ruleSoft).frame(height: 1).padding(.leading, Theme.Space.l) }

    private func field(_ label: String, text: Binding<String>) -> some View {
        TextField(label, text: text)
            .font(Theme.ui(17)).foregroundStyle(Theme.ink)
            .padding(.horizontal, Theme.Space.l).frame(height: Theme.rowHeight)
    }

    private func socialField(_ social: Social, text: Binding<String>) -> some View {
        HStack(spacing: Theme.Space.s) {
            Text(social.label).font(Theme.ui(17)).foregroundStyle(Theme.ink).frame(width: 96, alignment: .leading)
            Text(social.prefix).font(Theme.ui(17)).foregroundStyle(Theme.faint)
            TextField("handle", text: text)
                .font(Theme.ui(17)).foregroundStyle(Theme.ink)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
        }
        .padding(.horizontal, Theme.Space.l).frame(height: Theme.rowHeight)
    }
}

struct MakeBadgeView: View {
    var onSaved: (Profile) -> Void = { _ in }

    @EnvironmentObject private var supabase: SupabaseService
    @State private var draft: BadgeDraft = {
        var d = BadgeDraft()
        d.firstName = UserDefaults.standard.string(forKey: "appleGivenName") ?? ""
        d.lastName = UserDefaults.standard.string(forKey: "appleFamilyName") ?? ""
        return d
    }()
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                Text("Make your badge").font(Theme.title()).tracking(Theme.titleTracking).foregroundStyle(Theme.ink)
                BadgeFields(draft: $draft)
                if let error { Text(error).font(Theme.ui(14)).foregroundStyle(Theme.danger) }
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.top, Theme.Space.l)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.paper)
        .safeAreaInset(edge: .bottom) {
            Button(saving ? "Saving…" : "Next") { Task { await save() } }
                .buttonStyle(.primary)
                .disabled(!draft.isValid || saving)
                .padding(.horizontal, Theme.Space.xl).padding(.vertical, Theme.Space.m)
                .background(Theme.paper)
        }
    }

    private func save() async {
        guard let id = supabase.session?.user.id else { return }
        saving = true; error = nil
        let profile = draft.profile(id: id)
        do {
            try await supabase.saveProfile(profile)
            onSaved(profile)
        } catch {
            self.error = "Couldn't save your badge. Check your connection and try again."
        }
        saving = false
    }
}

#Preview { MakeBadgeView().environmentObject(SupabaseService.shared) }
