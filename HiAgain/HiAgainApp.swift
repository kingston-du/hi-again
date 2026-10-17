import SwiftUI

@main
struct HiAgainApp: App {
    @StateObject private var supabase = SupabaseService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(supabase)
                .preferredColorScheme(.light)
        }
    }
}
