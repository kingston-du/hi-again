#if DEBUG
import SwiftUI

/// B4 check: read the same card twice and compare short codes; check location returns in 2 seconds.
struct DebugScanView: View {
    @State private var reads: [String] = []
    @State private var placeLine = "—"
    @State private var error: String?

    var body: some View {
        List {
            Section("Card") {
                Button("Scan a card") { Task { await scan() } }
                ForEach(Array(reads.enumerated()), id: \.offset) { i, code in
                    Text("Read \(i + 1): CARD \(code)").font(Theme.mono(14))
                }
                if reads.count >= 2 {
                    Text(Set(reads.suffix(2)).count == 1 ? "Same both times ✓" : "Different ✗ (this card won't work)")
                }
                if let error { Text(error).foregroundStyle(.red) }
                if !reads.isEmpty { Button("Clear", role: .destructive) { reads = [] } }
            }
            Section("Location") {
                Button("Get place") { Task { await place() } }
                Text(placeLine).font(Theme.mono(14))
            }
        }
        .navigationTitle("Debug scan")
    }

    private func scan() async {
        error = nil
        do {
            let uid = try await NFCService.shared.readCardUID()
            reads.append(CardHasher.shortCode(CardHasher.hash(uid)) + " · \(uid.count)B")
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func place() async {
        let start = Date()
        let p = try? await LocationService.shared.currentPlace()
        let ms = Int(Date().timeIntervalSince(start) * 1000)
        placeLine = p.map { "\($0.name ?? "no name") · \(String(format: "%.4f, %.4f", $0.lat, $0.lng)) · \(ms) ms" } ?? "nil · \(ms) ms"
    }
}
#endif
