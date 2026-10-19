import SwiftUI

@main
@MainActor
struct PasteItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let runtime = AppRuntime.shared

    init() {
        // Settings can render before applicationDidFinishLaunching.
        AppDelegate.configureLocalization()
    }

    var body: some Scene {
        Settings {
            SettingsSceneBridge(appState: runtime.state)
                .frame(width: 1, height: 1)
        }
    }
}
