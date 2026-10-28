import AppKit
import PasteItCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let runtime = AppRuntime.shared

    static func configureLocalization() {
        LanguageRepairController.shared.configure(LocalizationResources.resolve())
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.configureLocalization()
        // Tahoe injects gear/etc. on Preferences/Settings; opt out before any menu opens.
        MenuIconPolicy.disableSystemInjectedIcons()
        NSApp.setActivationPolicy(.accessory)
        runtime.start()
        LanguageRepairController.shared.revealSettings = { [runtime] in
            SettingsWindowController.shared.showLanguageRepair(appState: runtime.state)
        }
        let arguments = ProcessInfo.processInfo.arguments
        if !arguments.contains("--ui-review") && LanguageRepairController.shared.needsRepair {
            DispatchQueue.main.async { LanguageRepairPrompt.presentIfNeeded() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // A second click on the app should expose a window for this menu-bar app.
        if !flag { SettingsWindowController.shared.show(appState: runtime.state) }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        runtime.stop()
    }
}
