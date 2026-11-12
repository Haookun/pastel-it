import AppKit
import SwiftUI

/// Install / What's New tutorial window. Mirrors `SettingsWindowController` activation policy handling.
@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let shared = OnboardingWindowController()

    private var window: NSWindow?
    private var wasAccessory = true
    private var settings: AppSettings?
    private var flow: OnboardingFlow = .install

    var isVisible: Bool {
        window?.isVisible == true
    }

    func show(
        settings: AppSettings,
        flow: OnboardingFlow,
        source: String
    ) {
        self.settings = settings
        self.flow = flow
        wasAccessory = NSApp.activationPolicy() == .accessory
        if wasAccessory {
            NSApp.setActivationPolicy(.regular)
        }

        let title = "Pastel it！"
        if let existing = window {
            existing.title = title
            existing.setContentSize(NSSize(width: 640, height: 540))
            existing.minSize = NSSize(width: 640, height: 540)
            existing.maxSize = NSSize(width: 640, height: 540)
            existing.contentViewController = makeHostingController(
                settings: settings,
                flow: flow
            )
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            existing.center()
            return
        }

        let window = makeWindow(settings: settings, flow: flow)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.center()
    }

    func close() {
        window?.close()
    }

    private func makeWindow(
        settings: AppSettings,
        flow: OnboardingFlow
    ) -> NSWindow {
        let hosting = makeHostingController(settings: settings, flow: flow)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 540),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pastel it！"
        window.contentViewController = hosting
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.isOpaque = true
        window.backgroundColor = .windowBackgroundColor
        window.setContentSize(NSSize(width: 640, height: 540))
        window.minSize = NSSize(width: 640, height: 540)
        window.maxSize = NSSize(width: 640, height: 540)
        return window
    }

    private func makeHostingController(
        settings: AppSettings,
        flow: OnboardingFlow
    ) -> NSHostingController<OnboardingView> {
        let root = OnboardingView(
            settings: settings,
            flow: flow
        ) { [weak self] in
            self?.close()
        }
        return NSHostingController(rootView: root)
    }

    func windowWillClose(_ notification: Notification) {
        // Closing a retained window does not unmount SwiftUI's repeating demo tasks.
        if let closingWindow = notification.object as? NSWindow {
            closingWindow.contentViewController = nil
        }
        window = nil
        if let settings {
            switch flow {
            case .install:
                if !settings.hasCompletedOnboarding {
                    settings.hasCompletedOnboarding = true
                }
                settings.seenWhatsNewContentVersion = AppSettings.currentWhatsNewContentVersion
            case .update:
                settings.seenWhatsNewContentVersion = AppSettings.currentWhatsNewContentVersion
            }
        }
        guard wasAccessory else { return }
        if SettingsWindowController.shared.isVisible { return }
        NSApp.setActivationPolicy(.accessory)
    }
}
