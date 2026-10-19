import AppKit
import PasteItCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let runtime = AppRuntime.shared

    static func configureLocalization() {
        // Release apps embed SwiftPM resources in Contents/Resources. The
        // generated Bundle.module accessor can look only at the app root and
        // the build machine's path, so resolve the packaged bundle first.
        if let resourceURL = Bundle.main.url(forResource: "PasteIt_PasteIt", withExtension: "bundle"),
           let resourceBundle = Bundle(url: resourceURL) {
            L10n.bundle = resourceBundle
        } else {
            L10n.bundle = Bundle.module
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.configureLocalization()
        // Tahoe injects gear/etc. on Preferences/Settings; opt out before any menu opens.
        MenuIconPolicy.disableSystemInjectedIcons()
        NSApp.setActivationPolicy(.accessory)
        runtime.start()
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
