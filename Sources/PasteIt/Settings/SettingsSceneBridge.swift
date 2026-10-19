import AppKit
import Combine
import SwiftUI

/// Keep the standard Settings menu command, but route it to the one native
/// preferences window. SwiftUI's Settings window enforces fixed sizing on some
/// macOS versions even when windowResizability is explicitly configured.
struct SettingsSceneBridge: NSViewRepresentable {
    let appState: AppState
    func makeNSView(context: Context) -> BridgeView { BridgeView(appState: appState) }
    func updateNSView(_ view: BridgeView, context: Context) {}

    final class BridgeView: NSView {
        private let appState: AppState
        private var activation: AnyCancellable?

        init(appState: AppState) {
            self.appState = appState
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            activation = nil
            guard let window else { return }
            activation = NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification, object: window)
                .sink { [weak self] _ in
                    Task { @MainActor in self?.redirect() }
                }
            DispatchQueue.main.async { [weak self] in self?.redirect() }
        }

        private func redirect() {
            guard let window, window.isVisible else { return }
            window.orderOut(nil)
            SettingsWindowController.shared.show(appState: appState)
        }
    }
}
