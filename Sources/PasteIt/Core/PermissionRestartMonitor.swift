import AppKit
import Combine
import PasteItCore

/// Lives with the runtime so granting access from onboarding or System Settings
/// is observed even when the preferences window is closed.
@MainActor
final class PermissionRestartMonitor: ObservableObject {
    static let shared = PermissionRestartMonitor()
    @Published private(set) var restartRecommended = false
    private var tracker = PermissionGrantTracker(granted: SystemPasteSynthesizer.isAccessibilityTrusted)
    private var timer: Timer?
    private var activationObserver: NSObjectProtocol?

    func start() {
        guard timer == nil else { return }
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let activationObserver { NotificationCenter.default.removeObserver(activationObserver) }
        activationObserver = nil
    }

    private func check() {
        guard tracker.update(granted: SystemPasteSynthesizer.isAccessibilityTrusted) else { return }
        restartRecommended = true
        let alert = NSAlert()
        alert.messageText = L10n.tr("permissions.restartTitle", default: "Restart Pastel it！ After Granting Access")
        alert.informativeText = L10n.tr("permissions.restartDetail", default: "Accessibility permission is now enabled. Please quit and reopen Pastel it！ so automatic pasting and Paste Stack can use the updated permission. Your clipboard history will be kept.")
        alert.addButton(withTitle: L10n.tr("permissions.understood", default: "Got It"))
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
