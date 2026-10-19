import AppKit
import SwiftUI
import PasteItCore

struct DirectPastePermissionView: View {
    @ObservedObject private var restartMonitor = PermissionRestartMonitor.shared
    @State private var trusted = SystemPasteSynthesizer.isAccessibilityTrusted

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(
                trusted
                    ? L10n.tr("action.permissionReady", default: "Direct paste is enabled")
                    : L10n.tr("action.permissionNeeded", default: "Direct paste needs Accessibility"),
                systemImage: trusted ? "checkmark.circle" : "info.circle"
            )
            if restartMonitor.restartRecommended {
                Text(L10n.tr("permissions.restartHint", default: "Permission updated. Quit and reopen Pastel it！ to finish applying it."))
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !trusted {
                Text(L10n.tr("action.permissionDetail", default: "Accessibility lets Pastel it！ send ⌘V to your destination app. You can still copy clips and paste them manually without granting access."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(L10n.tr("action.enablePaste", default: "Enable Direct Paste")) {
                    SystemPasteSynthesizer.openAccessibilitySettings()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            trusted = SystemPasteSynthesizer.isAccessibilityTrusted
        }
        .onAppear { trusted = SystemPasteSynthesizer.isAccessibilityTrusted }
    }
}
