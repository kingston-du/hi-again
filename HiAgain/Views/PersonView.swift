import SwiftUI

struct PersonView: View {
    let person: Person
    var onRemoved: () async -> Void = {}

    @EnvironmentObject private var supabase: SupabaseService
    @Environment(\.dismiss) private var dismiss

    @State private var noteText: String = ""
    @State private var isEditingNote = false
    @State private var errorMessage: String?
    @State private var confirmRemove = false

    private var meeting: Meeting? { person.meetings.first }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    PersonHeader(profile: person.profile)

                    let socials = Social.handles(of: person.profile)
                    if !socials.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(socials.enumerated()), id: \.offset) { index, pair in
                                if index > 0 { Divider().overlay(Theme.ruleSoft) }
                                SocialLinkRow(social: pair.0, handle: pair.1)
                            }
                        }
                        .groupBox()
                    }

                    WhereYouMetSection(
                        meeting: meeting,
                        noteText: $noteText,
                        isEditingNote: $isEditingNote,
                        onSaveNote: saveNote,
                        scrollProxy: proxy
                    )
                    .id("note")
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.vertical, Theme.Space.l)
                .padding(.bottom, Theme.Space.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.paper.ignoresSafeArea())
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Remove \(person.profile.firstName)", role: .destructive) {
                        confirmRemove = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .onAppear {
            noteText = meeting?.note ?? ""
        }
        .confirmationDialog(
            "Remove \(person.profile.firstName)?",
            isPresented: $confirmRemove,
            titleVisibility: .visible
        ) {
            Button("Remove \(person.profile.firstName)", role: .destructive) {
                Task { await remove() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll lose your note about them.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func saveNote() {
        guard let meeting else { return }
        Task {
            do {
                try await supabase.updateNote(meetingId: meeting.id, text: noteText)
                isEditingNote = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func remove() async {
        do {
            try await supabase.removePerson(id: person.id)
            await onRemoved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Subviews (easy for Claude to restyle)

private struct PersonHeader: View {
    let profile: Profile

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Sticker(firstName: profile.firstName, color: profile.badgeColor, size: .large)
                .frame(maxWidth: .infinity)

            if let last = profile.lastName, !last.isEmpty {
                Text("\(profile.firstName) \(last)")
                    .font(Theme.ui(15))
                    .foregroundStyle(Theme.muted)
            }
        }
    }
}

private struct WhereYouMetSection: View {
    let meeting: Meeting?
    @Binding var noteText: String
    @Binding var isEditingNote: Bool
    let onSaveNote: () -> Void
    var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Where you met")
                .font(Theme.ui(15, weight: .semibold))
                .foregroundStyle(Theme.ink)

            HStack(alignment: .center, spacing: Theme.Space.l) {
                Stamp(
                    place: meeting?.placeName,
                    date: meeting?.metAt ?? Date(),
                    diameter: 92
                )

                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(meeting?.placeName ?? "Somewhere")
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    if let metAt = meeting?.metAt {
                        Text(Self.dateTime.string(from: metAt))
                            .font(Theme.ui(15))
                            .foregroundStyle(Theme.muted)
                    }
                }
                Spacer(minLength: 0)
            }

            NoteEditor(
                text: $noteText,
                isEditing: $isEditingNote,
                onSave: onSaveNote,
                scrollProxy: scrollProxy
            )
        }
    }

    private static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, MMM d · h:mm a"
        return f
    }()
}

private struct NoteEditor: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onSave: () -> Void
    var scrollProxy: ScrollViewProxy? = nil

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if isEditing {
                TextField("What do you want to remember?", text: $text, axis: .vertical)
                    .font(Theme.ui(16))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(3...6)
                    .focused($focused)
                HStack {
                    Spacer()
                    Button("Save", action: onSave)
                        .font(Theme.ui(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
            } else {
                Button {
                    isEditing = true
                } label: {
                    HStack {
                        Text(display)
                            .font(Theme.ui(16))
                            .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                             ? Theme.faint : Theme.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .overlay(alignment: .top) {
            Theme.noteLine.frame(height: 1).padding(.top, Theme.Space.l + 22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Theme.rule, lineWidth: 1)
        )
        .onChange(of: isEditing) { _, editing in
            if editing {
                focused = true
            } else {
                focused = false
            }
        }
        .onChange(of: focused) { _, isFocused in
            guard isFocused, let scrollProxy else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.25)) {
                    scrollProxy.scrollTo("note", anchor: .center)
                }
            }
        }
    }

    private var display: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Add a note" : trimmed
    }
}

#Preview {
    NavigationStack {
        PersonView(person: Person(
            profile: Profile(
                id: UUID(),
                firstName: "Maya",
                lastName: "Chen",
                badgeColor: .red,
                instagram: "maya",
                snapchat: nil,
                linkedin: nil
            ),
            meetings: [
                Meeting(
                    id: UUID(),
                    ownerId: UUID(),
                    otherId: UUID(),
                    metAt: Date(),
                    lat: nil,
                    lng: nil,
                    placeName: "HUB",
                    note: "Does robotics"
                )
            ]
        ))
    }
    .environmentObject(SupabaseService.shared)
}
