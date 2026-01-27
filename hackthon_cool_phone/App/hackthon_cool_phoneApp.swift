import SwiftUI
import SwiftData
import AppIntents

@main
struct hackthon_cool_phoneApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        _ = VolumeButtonManager.shared
        print("🚀 应用启动，音量监听已初始化")
        
        if #available(iOS 16.0, *) {
            CallAppShortcuts.updateAppShortcutParameters()
        }
    }

    @State private var isShortcutLaunch = false

    var body: some Scene {
        WindowGroup {
            RootView(forceHideSplash: $isShortcutLaunch)
                .modelContainer(sharedModelContainer)
                .onOpenURL { url in
                    print("🔗 Received URL: \(url)")
                    if url.scheme == "coolphone" {
                        // User requested immediate trigger (direct popup)
                        isShortcutLaunch = true // Bypass Splash Immediately
                        
                        // Set sticky flag (Robust for cold launch)
                        AICallManager.shared.hasPendingInstantCall = true
                        
                        // Also trigger flow just in case
                        AICallManager.shared.scheduleIncomingCall(delayMs: 100)
                    }
                }
        }
    }
}
