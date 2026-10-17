import SwiftUI

/// No session → Welcome. Session but no profile → Make your badge → Link your card. Otherwise → People.
struct RootView: View {
    @EnvironmentObject private var supabase: SupabaseService
    @State private var profile: Profile?
    @State private var loadingProfile = false
    @State private var needsCardLink = false

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            if supabase.session == nil {
                WelcomeView()
            } else if loadingProfile {
                ProgressView().tint(Theme.violet)
            } else if profile == nil {
                MakeBadgeView { saved in
                    profile = saved
                    needsCardLink = true
                }
            } else if needsCardLink {
                LinkCardView { needsCardLink = false }
            } else {
                PeopleView()
            }
        }
        .task(id: supabase.session?.user.id) { await loadProfile() }
    }

    private func loadProfile() async {
        guard supabase.session != nil else { profile = nil; return }
        loadingProfile = true
        profile = try? await supabase.myProfile()
        loadingProfile = false
    }
}
