import SwiftUI

struct LinkCardView: View {
    var onDone: () -> Void = {}

    @EnvironmentObject private var supabase: SupabaseService
    @State private var shortCode: String?
    @State private var message: String?
    @State private var working = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            Text("Link your card").font(Theme.title()).tracking(Theme.titleTracking).foregroundStyle(Theme.ink)
                .padding(.top, Theme.Space.l)

            CardOnPhoneDrawing()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Space.xl)

            Text("Hold your student ID to the top of your phone.")
                .font(Theme.ui(17, weight: .semibold)).foregroundStyle(Theme.ink)
            Text("People tap it to get your badge. Only a scrambled code is saved, never the card number.")
                .font(Theme.ui(15)).foregroundStyle(Theme.muted)

            if let shortCode {
                Label("Linked · CARD \(shortCode)", systemImage: "checkmark.circle.fill")
                    .font(Theme.ui(15, weight: .semibold)).foregroundStyle(Theme.ink)
            }
            if let message {
                Text(message).font(Theme.ui(15)).foregroundStyle(Theme.danger)
            }

            Spacer()

            if shortCode == nil {
                Button(working ? "Scanning…" : "Scan my card") { Task { await link() } }
                    .buttonStyle(.primary).disabled(working)
                Button("Skip for now", action: onDone).buttonStyle(.secondary)
            } else {
                Button("Done", action: onDone).buttonStyle(.primary)
            }
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.bottom, Theme.Space.l)
        .background(Theme.paper)
    }

    private func link() async {
        working = true; message = nil
        defer { working = false }
        do {
            let hash = CardHasher.hash(try await NFCService.shared.readCardUID())
            switch try await supabase.claimCard(hash: hash) {
            case .linked, .alreadyYours: shortCode = CardHasher.shortCode(hash)
            case .taken: message = "This card is already linked to someone else."
            }
        } catch NFCError.cancelled {
            return
        } catch let error as NFCError {
            message = error.localizedDescription
        } catch {
            message = "Couldn't link your card. Check your connection and try again."
        }
    }
}

/// A card held at the top of an iPhone.
private struct CardOnPhoneDrawing: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 30).strokeBorder(Theme.ink, lineWidth: 3)
                .frame(width: 130, height: 220)
                .offset(y: 50)
            RoundedRectangle(cornerRadius: 10).fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.ink, lineWidth: 2))
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Circle().fill(Theme.rule).frame(width: 22, height: 22)
                        RoundedRectangle(cornerRadius: 2).fill(Theme.rule).frame(width: 70, height: 6)
                        RoundedRectangle(cornerRadius: 2).fill(Theme.rule).frame(width: 46, height: 6)
                    }
                    .padding(.leading, 14)
                }
                .frame(width: 150, height: 94)
                .rotationEffect(.degrees(-8))
            Image(systemName: "wave.3.up")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.stamp)
                .offset(y: 100)
        }
        .frame(height: 280)
        .accessibilityHidden(true)
    }
}

#Preview { LinkCardView().environmentObject(SupabaseService.shared) }
