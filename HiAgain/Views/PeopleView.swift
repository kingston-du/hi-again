import SwiftUI

struct PeopleView: View {
    @EnvironmentObject private var supabase: SupabaseService
    @State private var people: [Person] = []
    @State private var myProfile: Profile?
    @State private var showMe = false
    @State private var loadError: String?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Theme.paper.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    PeopleHeader(
                        count: people.count,
                        myProfile: myProfile,
                        onMe: { showMe = true }
                    )
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.top, Theme.Space.m)
                    .padding(.bottom, Theme.Space.l)

                    if people.isEmpty {
                        PeopleEmptyState()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(people) { person in
                                Button {
                                    path.append(person)
                                } label: {
                                    PeopleRow(person: person)
                                }
                                .listRowInsets(EdgeInsets(
                                    top: Theme.Space.s,
                                    leading: Theme.Space.l,
                                    bottom: Theme.Space.s,
                                    trailing: Theme.Space.l
                                ))
                                .listRowBackground(Theme.paper)
                                .listRowSeparatorTint(Theme.ruleSoft)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { await load() }
                    }
                }

                ScanButton { startScan() }
                    .padding(.bottom, Theme.Space.xl)
            }
            .navigationDestination(for: Person.self) { person in
                PersonView(person: person) {
                    path.removeLast()
                    await load()
                }
            }
            .sheet(isPresented: $showMe) {
                MeView()
            }
            .task { await load() }
            .alert("Couldn't load people", isPresented: Binding(
                get: { loadError != nil },
                set: { if !$0 { loadError = nil } }
            )) {
                Button("OK", role: .cancel) { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    /// B7 fills this in (NFC → scanCard → ScanResultView).
    private func startScan() {}

    private func load() async {
        do {
            async let fetchedPeople = supabase.people()
            async let fetchedProfile = supabase.myProfile()
            people = try await fetchedPeople
            myProfile = try await fetchedProfile
        } catch {
            loadError = error.localizedDescription
        }
    }
}

// MARK: - Subviews (Claude can swap styling later)

private struct PeopleHeader: View {
    let count: Int
    let myProfile: Profile?
    let onMe: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
                Text("\(count)")
                    .font(Theme.title(34))
                    .tracking(Theme.titleTracking)
                    .foregroundStyle(Theme.stamp)
                Text(count == 1 ? "person you've met" : "people you've met")
                    .font(Theme.title(28))
                    .tracking(Theme.titleTracking)
                    .foregroundStyle(Theme.ink)
            }
            Spacer(minLength: Theme.Space.m)
            Button(action: onMe) {
                MeInitialCircle(profile: myProfile)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Me")
        }
    }
}

private struct MeInitialCircle: View {
    let profile: Profile?

    private var initial: String {
        let name = profile?.firstName ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    private var color: BadgeColor { profile?.badgeColor ?? .red }

    var body: some View {
        Text(initial)
            .font(Theme.marker(22))
            .foregroundStyle(Theme.onBadge(color))
            .frame(width: 36, height: 36)
            .background(Theme.badge(color), in: Circle())
    }
}

private struct PeopleRow: View {
    let person: Person

    private var meeting: Meeting? { person.meetings.first }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.m) {
            Sticker(
                firstName: person.profile.firstName,
                color: person.profile.badgeColor,
                size: .row
            )

            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(person.profile.firstName)
                    .font(Theme.ui(17, weight: .semibold))
                    .foregroundStyle(Theme.ink)

                Text(metaLine)
                    .font(Theme.ui(13, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)

                if let preview = notePreview {
                    Text(preview)
                        .font(Theme.ui(14).italic())
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Space.xs)
        .contentShape(Rectangle())
    }

    private var metaLine: String {
        let place = meeting?.placeName?.uppercased() ?? "SOMEWHERE"
        let time = Self.timeFormatter.string(from: person.lastMet).uppercased()
        return "\(place) · \(time)"
    }

    private var notePreview: String? {
        guard let note = meeting?.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty else { return nil }
        return note.split(separator: "\n", maxSplits: 1).first.map(String.init)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE h:mm a"
        return f
    }()
}

private struct PeopleEmptyState: View {
    var body: some View {
        VStack(spacing: Theme.Space.m) {
            Text("Nobody yet. Tap a card to meet someone.")
                .font(Theme.ui(17))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Space.xl)

            Image(systemName: "arrow.down")
                .font(Theme.ui(22, weight: .semibold))
                .foregroundStyle(Theme.faint)
                .padding(.top, Theme.Space.l)
        }
        .padding(.bottom, Theme.scanButtonSize + Theme.Space.xxl)
    }
}

#Preview {
    PeopleView()
        .environmentObject(SupabaseService.shared)
}
