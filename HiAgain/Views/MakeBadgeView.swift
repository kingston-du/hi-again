import SwiftUI

/// Editable badge fields. Make your badge uses it, and so does Edit badge in Me.
struct BadgeDraft: Equatable {
    var firstName = ""
    var lastName = ""
    var color: BadgeColor = .red
    var bio = ""
    var instagram = ""
    var snapchat = ""
    var linkedin = ""
    var tiktok = ""
    var phone = ""
    var discord = ""
    var email = ""

    init() {}

    init(_ p: Profile) {
        firstName = p.firstName; lastName = p.lastName ?? ""; color = p.badgeColor
        bio = p.bio ?? ""
        instagram = p.instagram ?? ""; snapchat = p.snapchat ?? ""; linkedin = p.linkedin ?? ""
        tiktok = p.tiktok ?? ""; phone = p.phone ?? ""; discord = p.discord ?? ""; email = p.email ?? ""
    }

    var isValid: Bool { !clean(firstName).isEmpty }

    func profile(id: UUID, slug: String? = nil) -> Profile {
        Profile(
            id: id,
            firstName: clean(firstName),
            lastName: clean(lastName).isEmpty ? nil : clean(lastName),
            badgeColor: color,
            bio: bioValue(bio),
            instagram: handle(instagram),
            snapchat: handle(snapchat),
            linkedin: handle(linkedin),
            tiktok: handle(tiktok),
            phone: phoneValue(phone),
            discord: handle(discord),
            email: emailValue(email),
            slug: slug
        )
    }

    private func clean(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func bioValue(_ s: String) -> String? {
        let t = clean(s)
        guard !t.isEmpty else { return nil }
        return String(t.prefix(160))
    }

    private func phoneValue(_ s: String) -> String? {
        let t = clean(s)
        guard !t.isEmpty else { return nil }
        let allowed = t.filter { $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " || $0 == "(" || $0 == ")" }
        return allowed.isEmpty ? nil : String(allowed.prefix(32))
    }

    private func emailValue(_ s: String) -> String? {
        let t = clean(s).lowercased()
        return t.isEmpty ? nil : String(t.prefix(120))
    }

    /// Strips "@", "in/" and URL prefixes; nil if empty.
    private func handle(_ s: String) -> String? {
        var h = clean(s)
        let prefixes = [
            "https://", "http://", "www.",
            "instagram.com/", "snapchat.com/add/", "linkedin.com/in/",
            "tiktok.com/@", "tiktok.com/", "@", "in/",
        ]
        for prefix in prefixes where h.lowercased().hasPrefix(prefix) {
            h = String(h.dropFirst(prefix.count))
        }
        h = h.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        return h.isEmpty ? nil : h
    }
}

/// Live sticker preview, color swatches, names, bio and contacts.
struct BadgeFields: View {
    @Binding var draft: BadgeDraft
    var scrollProxy: ScrollViewProxy? = nil

    private enum Field: Hashable {
        case firstName, lastName, bio
        case instagram, snapchat, linkedin, tiktok, phone, discord, email
    }

    @FocusState private var focused: Field?

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
                field("First name", text: $draft.firstName, field: .firstName).textContentType(.givenName)
                divider
                field("Last name", text: $draft.lastName, field: .lastName).textContentType(.familyName)
            }
            .groupBox()

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                TextField("Short bio (school, year…)", text: $draft.bio, axis: .vertical)
                    .font(Theme.ui(17)).foregroundStyle(Theme.ink)
                    .lineLimit(2...3)
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.vertical, Theme.Space.m)
                    .focused($focused, equals: .bio)
                    .id(Field.bio)
                    .onChange(of: draft.bio) { _, next in
                        if next.count > 160 { draft.bio = String(next.prefix(160)) }
                    }
                .groupBox()
                Text("Optional · \(draft.bio.count)/160")
                    .font(Theme.ui(13)).foregroundStyle(Theme.muted)
                    .padding(.leading, Theme.Space.l)
            }

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                VStack(spacing: 0) {
                    socialField(.instagram, text: $draft.instagram, field: .instagram)
                    divider
                    socialField(.snapchat, text: $draft.snapchat, field: .snapchat)
                    divider
                    socialField(.linkedin, text: $draft.linkedin, field: .linkedin)
                    divider
                    socialField(.tiktok, text: $draft.tiktok, field: .tiktok)
                    divider
                    socialField(.phone, text: $draft.phone, field: .phone, placeholder: "number")
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    divider
                    socialField(.discord, text: $draft.discord, field: .discord)
                    divider
                    socialField(.email, text: $draft.email, field: .email, placeholder: "you@school.edu")
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }
                .groupBox()
                Text("Optional").font(Theme.ui(13)).foregroundStyle(Theme.muted).padding(.leading, Theme.Space.l)
            }
        }
        .onChange(of: focused) { _, field in
            guard let field, let scrollProxy else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.25)) {
                    scrollProxy.scrollTo(field, anchor: .center)
                }
            }
        }
    }

    private var divider: some View { Rectangle().fill(Theme.ruleSoft).frame(height: 1).padding(.leading, Theme.Space.l) }

    private func field(_ label: String, text: Binding<String>, field: Field) -> some View {
        TextField(label, text: text)
            .font(Theme.ui(17)).foregroundStyle(Theme.ink)
            .padding(.horizontal, Theme.Space.l).frame(height: Theme.rowHeight)
            .focused($focused, equals: field)
            .id(field)
    }

    private func socialField(
        _ social: Social,
        text: Binding<String>,
        field: Field,
        placeholder: String = "handle"
    ) -> some View {
        HStack(spacing: Theme.Space.s) {
            Text(social.label).font(Theme.ui(17)).foregroundStyle(Theme.ink).frame(width: 96, alignment: .leading)
            if !social.prefix.isEmpty {
                Text(social.prefix).font(Theme.ui(17)).foregroundStyle(Theme.faint)
            }
            TextField(placeholder, text: text)
                .font(Theme.ui(17)).foregroundStyle(Theme.ink)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .focused($focused, equals: field)
        }
        .padding(.horizontal, Theme.Space.l).frame(height: Theme.rowHeight)
        .id(field)
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    Text("Make your badge").font(Theme.title()).tracking(Theme.titleTracking).foregroundStyle(Theme.ink)
                    BadgeFields(draft: $draft, scrollProxy: proxy)
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
