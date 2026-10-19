import AppKit
import PasteItCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let runtime = AppRuntime.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Release apps embed SwiftPM resources in Contents/Resources. The
        // generated Bundle.module accessor can look only at the app root and
        // the build machine's path, so resolve the packaged bundle first.
        if let resourceURL = Bundle.main.url(forResource: "PasteIt_PasteIt", withExtension: "bundle"),
           let resourceBundle = Bundle(url: resourceURL) {
            L10n.bundle = resourceBundle
        } else {
            L10n.bundle = Bundle.module
        }
        // Tahoe injects gear/etc. on Preferences/Settings; opt out before any menu opens.
        MenuIconPolicy.disableSystemInjectedIcons()
        NSApp.setActivationPolicy(.accessory)
        runtime.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        runtime.stop()
    }
}
