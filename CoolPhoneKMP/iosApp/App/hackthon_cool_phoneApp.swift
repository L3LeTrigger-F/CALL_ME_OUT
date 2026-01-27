import SwiftUI
import SwiftData

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
    }

    var body: some Scene {
        WindowGroup {
            RootView()  // ✅ 使用 RootView 替代 ContentView
                .modelContainer(sharedModelContainer)
        }
    }
}
