import SwiftUI

/// What one tap of the Scan button produced. `nil` from `Scanner.scan()` means stay put (cancelled).
struct ScanResult: Identifiable {
    let id = UUID()
    let outcome: ScanOutcome
    let place: Place?
    let at: Date
}

enum Scanner {
    enum Failure: Error { case unreadable, offline }

    /// NFC read → hash → place (2 s max, started in parallel) → scan_card. Returns nil if the person cancelled.
    @MainActor
    static func scan() async throws -> ScanResult? {
        async let place = try? LocationService.shared.currentPlace()
        let uid: Data
        do {
            uid = try await NFCService.shared.readCardUID()
        } catch NFCError.cancelled {
            return nil
        } catch {
            throw Failure.unreadable
        }
        let hash = CardHasher.hash(uid)
        let p = await place
        do {
            let outcome = try await SupabaseService.shared.scanCard(hash: hash, place: p)
            return ScanResult(outcome: outcome, place: p, at: .now)
        } catch {
            throw Failure.offline
        }
    }
}

/// The full-screen moment after a tap.
struct ScanResultView: View {
    let result: ScanResult
    var onDone: () -> Void = {}

    var body: some View {
        switch result.outcome {
        case let .met(profile, meetingId, timesMet):
            MetView(profile: profile, meetingId: meetingId, metBefore: timesMet > 1, place: result.place, at: result.at, onDone: onDone)
        case .unknown:
            UnknownCardView(onDone: onDone)
        case .ownCard:
            OwnCardView(onDone: onDone)
        }
    }
}

// MARK: - Met

private struct MetView: View {
    let profile: Profile
    let meetingId: UUID
    let metBefore: Bool
    let place: Place?
    let at: Date
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropped = false
    @State private var stamped = false
    @State private var note = ""
    @State private var saving = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    Text(at.formatted(.dateTime.weekday(.wide).hour().minute()))
                        .font(Theme.ui(15, weight: .semibold)).foregroundStyle(.white.opacity(0.85))

                    ZStack(alignment: .bottomTrailing) {
                        Sticker(firstName: profile.firstName, color: profile.badgeColor == .red ? .black : profile.badgeColor,
                                size: .large, tilt: -3)
                        Stamp(place: place?.name, date: at, color: .white, rotation: 12)
                            .offset(x: 34, y: 58)
                            .scaleEffect(stamped ? 1 : 1.15)
                            .opacity(stamped ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Space.xl)
                    .offset(y: dropped ? 0 : -500)

                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        if metBefore {
                            Text("You've met before").font(Theme.ui(15, weight: .semibold)).foregroundStyle(.white.opacity(0.85))
                        }
                        Text("You met \(profile.firstName).")
                            .font(Theme.title(34)).tracking(Theme.titleTracking).foregroundStyle(.white)
                        if let name = place?.name {
                            Text(name).font(Theme.ui(17)).foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    VStack(spacing: Theme.Space.s) {
                        ForEach(Social.handles(of: profile), id: \.0) { social, handle in
                            SocialButton(social: social, handle: handle)
                        }
                    }

                    NoteCard(text: $note, focused: $noteFocused)
                        .id("note")
                }
                .padding(.horizontal, Theme.Space.xl)
                .padding(.top, Theme.Space.l)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollToFocused("note", proxy: proxy, anchor: .center, when: noteFocused)
            .background(Theme.stamp.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button(saving ? "Saving…" : "Done") { Task { await done() } }
                    .buttonStyle(.primaryInverted)
                    .disabled(saving)
                    .padding(.horizontal, Theme.Space.xl).padding(.vertical, Theme.Space.m)
                    .background(Theme.stamp)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: stamped)
        .task {
            if reduceMotion {
                dropped = true; stamped = true
                return
            }
            withAnimation(Theme.drop) { dropped = true }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(Theme.thunk) { stamped = true }
        }
    }

    private func done() async {
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            saving = true
            try? await SupabaseService.shared.updateNote(meetingId: meetingId, text: text)
            saving = false
        }
        onDone()
    }
}

/// White index card with blue rules: "What do you want to remember?"
struct NoteCard: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text("What do you want to remember?")
                .font(Theme.ui(15, weight: .semibold)).foregroundStyle(Theme.ink)
                .underline(color: Theme.stamp)
            TextField("Does robotics, from Portland", text: $text, axis: .vertical)
                .font(Theme.ui(17)).foregroundStyle(Theme.ink)
                .lineLimit(1...4)
                .focused(focused)
                .frame(minHeight: 66, alignment: .top)
                .background(alignment: .top) {
                    VStack(spacing: 22) {
                        ForEach(0..<4, id: \.self) { _ in Rectangle().fill(Theme.noteLine).frame(height: 1) }
                    }
                    .padding(.top, 21)
                }
                .clipped()
        }
        .padding(Theme.Space.l)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Unknown and own card

private struct UnknownCardView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            Spacer()
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Theme.ink.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .frame(width: 300, height: 196)
                .overlay(Text("?").font(Theme.marker(90)).foregroundStyle(Theme.ink.opacity(0.6)))
                .rotationEffect(.degrees(-3))
                .frame(maxWidth: .infinity)
            Spacer()
            Text("Not on the app yet.").font(Theme.title(34)).tracking(Theme.titleTracking).foregroundStyle(Theme.ink)
            Text("This card isn't linked to anyone. When they join and link it, tapping it will work.")
                .font(Theme.ui(17)).foregroundStyle(Theme.ink.opacity(0.75))
            Button("Done", action: onDone).buttonStyle(.primary).padding(.top, Theme.Space.l)
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.bottom, Theme.Space.l)
        .background(Theme.unknown.ignoresSafeArea())
    }
}

private struct OwnCardView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            Spacer()
            Text("That's you.").font(Theme.title(38)).tracking(Theme.titleTracking).foregroundStyle(Theme.ink)
            Text("Hand it to someone else, or tap theirs.").font(Theme.ui(17)).foregroundStyle(Theme.muted)
            Spacer()
            Button("Done", action: onDone).buttonStyle(.primary)
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.bottom, Theme.Space.l)
        .background(Theme.paper.ignoresSafeArea())
    }
}

#Preview("Met") {
    ScanResultView(result: ScanResult(
        outcome: .met(Profile(id: UUID(), firstName: "Maya", lastName: "Lee", badgeColor: .blue,
                              instagram: "maya.codes", snapchat: nil, linkedin: "mayalee"),
                      meetingId: UUID(), timesMet: 1),
        place: Place(name: "HUB", lat: 0, lng: 0), at: .now))
}

#Preview("Unknown") { ScanResultView(result: ScanResult(outcome: .unknown, place: nil, at: .now)) }
