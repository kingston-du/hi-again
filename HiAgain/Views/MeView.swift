import SwiftUI

struct MeView: View {
    @EnvironmentObject private var supabase: SupabaseService
    @Environment(\.dismiss) private var dismiss

    @State private var profile: Profile?
    @State private var linkedHash: String?
    @State private var editing = false
    @State private var draft = BadgeDraft()
    @State private var busy = false
    @State private var error: String?
    @State private var confirmUnlink = false
    @State private var showQRMeet = false

    var body: some View {
        NavigationStack {
            Group {
                if editing {
                    editBadge
                } else {
                    meHome
                }
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle(editing ? "Edit badge" : "You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editing ? "Cancel" : "Done") {
                        if editing {
                            editing = false
                            if let profile { draft = BadgeDraft(profile) }
                        } else {
                            dismiss()
                        }
                    }
                    .font(Theme.ui(17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                }
            }
            .task { await load() }
            .alert("Something went wrong", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK", role: .cancel) { error = nil }
            } message: {
                Text(error ?? "")
            }
            .confirmationDialog("Unlink your card?", isPresented: $confirmUnlink, titleVisibility: .visible) {
                Button("Unlink", role: .destructive) { Task { await unlink() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("People who tap it won't see your badge until you link again.")
            }
            .sheet(isPresented: $showQRMeet) {
                if let profile, let url = supabase.meetURL(for: profile) {
                    QRMeetSheet(url: url)
                }
            }
        }
    }

    // MARK: - Home

    private var meHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                if let profile {
                    Sticker(firstName: profile.firstName, color: profile.badgeColor, size: .large)
                        .frame(maxWidth: .infinity)

                    Text("This is what people see when they tap your card.")
                        .font(Theme.ui(15))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Edit badge") {
                        draft = BadgeDraft(profile)
                        editing = true
                    }
                    .buttonStyle(.secondary)

                    letThemScanSection

                    cardSection

                    Button("Sign out") { Task { await signOut() } }
                        .buttonStyle(.secondary)
                        .disabled(busy)
                } else {
                    ProgressView().tint(Theme.stamp).frame(maxWidth: .infinity)
                }

                if let error {
                    Text(error).font(Theme.ui(14)).foregroundStyle(Theme.danger)
                }
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.vertical, Theme.Space.l)
        }
    }

    private var letThemScanSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("No app?")
                .font(Theme.ui(15, weight: .semibold))
                .foregroundStyle(Theme.ink)

            Text("If they don’t have hi again., show a QR. They fill in their badge and land in your People.")
                .font(Theme.ui(15))
                .foregroundStyle(Theme.muted)

            Button("Let them scan") {
                Task { await ensureSlugAndShowQR() }
            }
            .buttonStyle(.primary)
            .disabled(busy || profile == nil)
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .groupBox()
    }

    private var cardSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Your card")
                .font(Theme.ui(15, weight: .semibold))
                .foregroundStyle(Theme.ink)

            Text(cardStatusLine)
                .font(Theme.ui(17))
                .foregroundStyle(Theme.ink)

            HStack(spacing: Theme.Space.m) {
                Button(busy ? "Scanning…" : "Relink") { Task { await relink() } }
                    .buttonStyle(.secondary)
                    .disabled(busy)

                if linkedHash != nil {
                    Button("Unlink") { confirmUnlink = true }
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.danger)
                        .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.buttonRadius)
                                .strokeBorder(Theme.rule, lineWidth: 1)
                        )
                        .disabled(busy)
                }
            }
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .groupBox()
    }

    private var cardStatusLine: String {
        if let linkedHash {
            return "Linked · \(CardHasher.shortCode(linkedHash))"
        }
        return "Not linked"
    }

    // MARK: - Edit

    private var editBadge: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    BadgeFields(draft: $draft, scrollProxy: proxy)
                    if let error {
                        Text(error).font(Theme.ui(14)).foregroundStyle(Theme.danger)
                    }
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, Theme.Space.l)
                .padding(.bottom, 80)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button(busy ? "Saving…" : "Save") { Task { await saveBadge() } }
                    .buttonStyle(.primary)
                    .disabled(!draft.isValid || busy)
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.vertical, Theme.Space.m)
                    .background(Theme.paper)
            }
        }
    }

    // MARK: - Actions

    private func load() async {
        do {
            var loaded = try await supabase.myProfile()
            // Assign a slug once if the DB column exists but the row predates QR meet.
            if var p = loaded, p.slug == nil || p.slug?.isEmpty == true {
                p.slug = SupabaseService.makeSlug()
                try await supabase.saveProfile(p)
                loaded = try await supabase.myProfile() ?? p
            }
            profile = loaded
            if let profile { draft = BadgeDraft(profile) }
            if let userId = supabase.session?.user.id {
                linkedHash = UserDefaults.standard.string(forKey: Self.hashKey(userId))
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func ensureSlugAndShowQR() async {
        guard var p = profile else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            if p.slug == nil || p.slug?.isEmpty == true {
                p.slug = SupabaseService.makeSlug()
                try await supabase.saveProfile(p)
                profile = try await supabase.myProfile() ?? p
            }
            guard supabase.meetURL(for: profile ?? p) != nil else {
                error = "Meet page URL isn’t set. Check MEET_PAGE_BASE_URL."
                return
            }
            showQRMeet = true
        } catch {
            self.error = "Couldn't prepare your QR. Check your connection and try again."
        }
    }

    private func saveBadge() async {
        guard let id = supabase.session?.user.id else { return }
        busy = true
        error = nil
        defer { busy = false }
        let next = draft.profile(id: id, slug: profile?.slug)
        do {
            try await supabase.saveProfile(next)
            profile = try await supabase.myProfile() ?? next
            editing = false
        } catch {
            self.error = "Couldn't save your badge. Check your connection and try again."
        }
    }

    private func relink() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            let hash = CardHasher.hash(try await NFCService.shared.readCardUID())
            switch try await supabase.claimCard(hash: hash) {
            case .linked, .alreadyYours:
                linkedHash = hash
                if let userId = supabase.session?.user.id {
                    UserDefaults.standard.set(hash, forKey: Self.hashKey(userId))
                }
            case .taken:
                error = "This card is already linked to someone else."
            }
        } catch NFCError.cancelled {
            return
        } catch let nfc as NFCError {
            error = nfc.localizedDescription
        } catch {
            self.error = "Couldn't link your card. Check your connection and try again."
        }
    }

    private func unlink() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await supabase.unlinkCard()
            linkedHash = nil
            if let userId = supabase.session?.user.id {
                UserDefaults.standard.removeObject(forKey: Self.hashKey(userId))
            }
        } catch {
            self.error = "Couldn't unlink your card. Check your connection and try again."
        }
    }

    private func signOut() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await supabase.signOut()
            dismiss()
        } catch {
            self.error = "Couldn't sign out. Try again."
        }
    }

    private static func hashKey(_ userId: UUID) -> String {
        "linkedCardHash.\(userId.uuidString)"
    }
}

// MARK: - QR meet sheet

private struct QRMeetSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Space.l) {
                if let image = QRCode.image(for: url.absoluteString, dimension: 240) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .padding(Theme.Space.l)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.groupRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.groupRadius)
                                .strokeBorder(Theme.rule, lineWidth: 1)
                        )
                }

                Text(url.absoluteString)
                    .font(Theme.ui(13))
                    .foregroundStyle(Theme.faint)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)

                ShareLink(item: url) {
                    Text("Share link")
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: Theme.buttonHeight)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.buttonRadius)
                                .strokeBorder(Theme.rule, lineWidth: 1)
                        )
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.top, Theme.Space.m)
            .padding(.bottom, Theme.Space.l)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Let them scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    MeView()
        .environmentObject(SupabaseService.shared)
}
