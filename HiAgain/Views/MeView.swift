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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                BadgeFields(draft: $draft)
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

    // MARK: - Actions

    private func load() async {
        do {
            profile = try await supabase.myProfile()
            if let profile { draft = BadgeDraft(profile) }
            if let userId = supabase.session?.user.id {
                linkedHash = UserDefaults.standard.string(forKey: Self.hashKey(userId))
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func saveBadge() async {
        guard let id = supabase.session?.user.id else { return }
        busy = true
        error = nil
        defer { busy = false }
        let next = draft.profile(id: id)
        do {
            try await supabase.saveProfile(next)
            profile = next
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

#Preview {
    MeView()
        .environmentObject(SupabaseService.shared)
}
