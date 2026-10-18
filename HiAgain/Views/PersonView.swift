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
        VStack(spacing: Theme.Space.m) {
            Sticker(firstName: profile.firstName, color: profile.badgeColor, size: .large)
                .frame(maxWidth: .infinity)

            VStack(spacing: Theme.Space.s) {
                if let last = profile.lastName, !last.isEmpty {
                    Text("\(profile.firstName) \(last)")
                        .font(Theme.ui(17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                if let bio = profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines), !bio.isEmpty {
                    Text(bio)
                        .font(Theme.ui(15))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

                Text(meeting?.placeName ?? "Somewhere")
                    .font(Theme.ui(17, weight: .semibold))
                    .foregroundStyle(Theme.ink)

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
}

private struct NoteLine: Identifiable, Equatable {
    let id: UUID
    var text: String
}

private struct NoteEditor: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onSave: () -> Void
    var scrollProxy: ScrollViewProxy? = nil

    @FocusState private var focusedLine: UUID?
    @State private var editLines: [NoteLine] = []

    private let maxLines = 8

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if isEditing {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach($editLines) { $line in
                        TextField(
                            line.id == editLines.first?.id ? "What do you want to remember?" : "",
                            text: $line.text
                        )
                        .font(Theme.ui(16))
                        .foregroundStyle(Theme.ink)
                        .focused($focusedLine, equals: line.id)
                        .submitLabel(.return)
                        .onSubmit { submit(after: line.id) }
                        .onChange(of: line.text) { _, newValue in
                            if newValue.contains("\n") {
                                splitPaste(in: line.id, newValue: newValue)
                            }
                            syncText()
                        }
                        .padding(.vertical, 6)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Theme.noteLine).frame(height: 1)
                        }
                    }
                }
                HStack {
                    Spacer()
                    Button("Save") {
                        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave()
                    }
                    .font(Theme.ui(15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                }
            } else {
                Button {
                    isEditing = true
                } label: {
                    RuledNoteLines(
                        lines: isEmpty ? ["Add a note"] : text.components(separatedBy: "\n"),
                        placeholder: isEmpty,
                        minRows: 1
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Theme.rule, lineWidth: 1)
        )
        .onChange(of: isEditing) { _, editing in
            if editing {
                beginEditing()
                // Scroll once when the keyboard opens — not on every new line (that twitched).
                if let scrollProxy {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            scrollProxy.scrollTo("note", anchor: .center)
                        }
                    }
                }
            } else {
                focusedLine = nil
            }
        }
    }

    private func beginEditing() {
        let parts = text.components(separatedBy: "\n")
        let rows = parts.isEmpty ? [""] : parts
        editLines = rows.map { NoteLine(id: UUID(), text: $0) }
        focusedLine = editLines.first?.id
    }

    private func syncText() {
        text = editLines.map(\.text).joined(separator: "\n")
    }

    private func submit(after id: UUID) {
        guard let index = editLines.firstIndex(where: { $0.id == id }) else { return }
        if editLines.count >= maxLines { return }
        let newLine = NoteLine(id: UUID(), text: "")
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            editLines.insert(newLine, at: index + 1)
            syncText()
            focusedLine = newLine.id
        }
    }

    private func splitPaste(in id: UUID, newValue: String) {
        guard let index = editLines.firstIndex(where: { $0.id == id }) else { return }
        let pieces = newValue.components(separatedBy: "\n")
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            editLines[index].text = pieces[0]
            var inserted: [NoteLine] = []
            for piece in pieces.dropFirst() {
                guard editLines.count + inserted.count < maxLines else { break }
                inserted.append(NoteLine(id: UUID(), text: piece))
            }
            if !inserted.isEmpty {
                editLines.insert(contentsOf: inserted, at: index + 1)
            }
            if editLines.count > maxLines {
                editLines = Array(editLines.prefix(maxLines))
            }
            if let last = inserted.last {
                focusedLine = last.id
            }
        }
    }
}

/// One blue rule under each text row so lines can't drift from the glyphs.
private struct RuledNoteLines: View {
    let lines: [String]
    var placeholder: Bool = false
    var minRows: Int = 1

    var body: some View {
        let rows = paddedRows
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, line in
                Text(line.isEmpty ? " " : line)
                    .font(Theme.ui(16))
                    .foregroundStyle(placeholder && index == 0 ? Theme.faint : Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Theme.noteLine).frame(height: 1)
                    }
            }
        }
    }

    private var paddedRows: [String] {
        var rows = lines.isEmpty ? [""] : lines
        while rows.count < minRows { rows.append("") }
        return rows
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
