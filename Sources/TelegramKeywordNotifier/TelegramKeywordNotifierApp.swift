import SwiftUI

@main
@MainActor
struct TelegramKeywordNotifierApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings: AppSettings
    @StateObject private var monitor: TelegramMonitor

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _monitor = StateObject(wrappedValue: TelegramMonitor(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings, monitor: monitor)
                .frame(minWidth: 760, minHeight: 680)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
