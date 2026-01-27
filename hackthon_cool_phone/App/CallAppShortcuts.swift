import AppIntents
import ComposeApp

// Available on iOS 16.0+
@available(iOS 16.0, *)
struct CallAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFakeCall(),
            phrases: [
                "Start a cool call in \(.applicationName)",
                "Call me out with \(.applicationName)",
                "Trigger fake call",
                "Start Cool Call"
            ],
            shortTitle: "Start Cool Call",
            systemImageName: "phone.badge.plus"
        )
    }
}

@available(iOS 16.0, *)
struct StartFakeCall: AppIntent {
    static var title: LocalizedStringResource = "Start Cool Call"
    static var description = IntentDescription("Immediately schedules a realistic fake call to help you escape.")
    static var openAppWhenRun: Bool = true 

    @MainActor
    func perform() async throws -> some IntentResult {
        print("📲 Shortcut triggered: Scheduling call...")
        // Immediate trigger (100ms)
        AICallManager.shared.scheduleIncomingCall(delayMs: 100)
        return .result(dialog: "Fake call incoming!")
    }
}
