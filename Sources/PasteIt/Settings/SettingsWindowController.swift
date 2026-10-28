import AppKit
import SwiftUI
import PasteItCore

/// Menu-bar (LSUIElement) apps often get a blank SwiftUI `Settings` scene.
/// Host preferences in an explicit `NSWindow` instead.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private var wasAccessory = true

    var isVisible: Bool {
        window?.isVisible == true
    }

    func show(appState: AppState) {
        if window?.isVisible != true {
            wasAccessory = NSApp.activationPolicy() == .accessory
        }
        if NSApp.activationPolicy() == .accessory {
            NSApp.setActivationPolicy(.regular)
        }

        let window = self.window ?? makeWindow(appState: appState)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(appState: AppState) -> NSWindow {
        let root = SettingsView(appState: appState)
        let hosting = NSHostingController(rootView: root)
        // Let AppKit own the window size instead of adopting the Form's ideal size.
        hosting.sizingOptions = []
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.tr("settings.windowTitle", default: "Pastel it！ Settings")
        // Standard AppKit titlebar: no fullSizeContentView and no empty
        // NSToolbar, so the in-content sidebar divider is the only vertical
        // line and stays aligned from top to bottom of the content area.
        window.contentViewController = hosting
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentMinSize = NSSize(width: 720, height: 500)
        window.center()
        let arguments = ProcessInfo.processInfo.arguments
        if !arguments.contains("--validation-session") && !arguments.contains("--ui-review") {
            window.setFrameAutosaveName("PasteItSettings")
        }
        return window
    }

    func windowWillClose(_ notification: Notification) {
        guard wasAccessory else { return }
        if OnboardingWindowController.shared.isVisible { return }
        NSApp.setActivationPolicy(.accessory)
    }
}
