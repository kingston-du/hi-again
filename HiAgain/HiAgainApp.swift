import SwiftUI

@main
struct HiAgainApp: App {
    @StateObject private var supabase = SupabaseService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-gallery") { DebugGalleryView() } else { RootView() }
                #else
                RootView()
                #endif
            }
                .environmentObject(supabase)
                .preferredColorScheme(.light)
        }
    }
}
