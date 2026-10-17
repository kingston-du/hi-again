import SwiftUI
import AuthenticationServices
import CryptoKit

struct WelcomeView: View {
    @EnvironmentObject private var supabase: SupabaseService
    @State private var nonce = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Wordmark()
                    .padding(.top, Theme.Space.s)

                Spacer(minLength: Theme.Space.xl)

                ZStack(alignment: .bottomTrailing) {
                    Sticker(firstName: "Maya", color: .red, size: .large, tilt: -4)
                    Stamp(place: "HUB", date: .now, rotation: 10).offset(x: 34, y: 58)
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: Theme.Space.xxl)

                Text("Remember the people you meet.")
                    .font(Theme.title(36)).tracking(Theme.titleTracking)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap someone's student ID and their name, socials and where you met stay with you.")
                    .font(Theme.ui(17)).foregroundStyle(Theme.muted)
                    .padding(.top, Theme.Space.m)

                Spacer(minLength: Theme.Space.xl)

                SignInWithAppleButton(.signIn) { request in
                    nonce = Self.randomNonce()
                    request.requestedScopes = [.fullName]
                    request.nonce = Self.sha256(nonce)
                } onCompletion: { result in
                    Task { await handle(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: Theme.buttonHeight)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))

                if let error {
                    Text(error).font(Theme.ui(14)).foregroundStyle(Theme.danger).padding(.top, Theme.Space.s)
                }

                #if DEBUG
                HStack(spacing: Theme.Space.xl) {
                    Button("Test account") {
                        Task { try? await supabase.signInAnonymously() }
                    }
                    NavigationLink("Debug scan") { DebugScanView() }
                }
                .font(Theme.ui(13)).foregroundStyle(Theme.faint)
                .frame(maxWidth: .infinity).padding(.top, Theme.Space.m)
                #endif
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.bottom, Theme.Space.l)
            .background(Theme.paper)
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) async {
        error = nil
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                error = "Couldn't sign in. Try again."
                return
            }
            if let given = credential.fullName?.givenName {
                UserDefaults.standard.set(given, forKey: "appleGivenName")
            }
            if let family = credential.fullName?.familyName {
                UserDefaults.standard.set(family, forKey: "appleFamilyName")
            }
            do {
                try await supabase.signInWithApple(idToken: idToken, nonce: nonce)
            } catch {
                self.error = "Couldn't sign in. Try again."
            }
        case .failure(let failure):
            if (failure as? ASAuthorizationError)?.code != .canceled {
                error = "Couldn't sign in. Try again."
            }
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).map { _ in chars[Int.random(in: 0..<chars.count)] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// `hi again.` with the period in stamp red.
struct Wordmark: View {
    var body: some View {
        (Text("hi again").foregroundColor(Theme.ink) + Text(".").foregroundColor(Theme.stamp))
            .font(Theme.wordmark())
            .accessibilityLabel("hi again")
    }
}

#Preview { WelcomeView().environmentObject(SupabaseService.shared) }
