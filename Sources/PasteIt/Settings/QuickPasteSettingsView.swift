import AppKit
import SwiftUI
import PasteItCore

struct QuickPasteSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var manager: HotkeyManager
    /// Refresh permission for direct pasting when returning from System Settings.
    @State private var accessibilityTrusted = SystemPasteSynthesizer.isAccessibilityTrusted

    private func scope(_ key: WritableKeyPath<QuickPasteScope, Bool>) -> Binding<Bool> {
        Binding(get: { settings.quickPasteScope[keyPath: key] }, set: {
            var value = settings.quickPasteScope
            value[keyPath: key] = $0
            settings.quickPasteScope = value
        })
    }

    var body: some View {
        Form {
            Section {
                Toggle(L10n.tr("quickPaste.enabled", default: "Enable quick paste"), isOn: Binding(
                    get: { settings.quickPasteEnabled },
                    set: { enabled in
                        if manager.setQuickPasteEnabled(enabled) { settings.quickPasteEnabled = enabled }
                    }
                ))
                ShortcutSettingsView(manager: manager, actions: [.quickPaste], showsReset: false,
                                     rowLabel: L10n.tr("shortcuts.binding", default: "Keyboard Shortcut"))
                Toggle(L10n.tr("quickPaste.text", default: "Text → plain text"), isOn: scope(\.text)).toggleStyle(.checkbox)
                Toggle(L10n.tr("quickPaste.images", default: "Images → OCR text"), isOn: scope(\.images)).toggleStyle(.checkbox)
                Toggle(L10n.tr("quickPaste.files", default: "Files → file names"), isOn: scope(\.fileNames)).toggleStyle(.checkbox)
                if settings.quickPasteScope.isEmpty {
                    Text(L10n.tr("quickPaste.emptyScope", default: "Select at least one content type to use quick paste."))
                        .font(.caption).foregroundStyle(.orange)
                }
            } header: {
                Text(L10n.tr("quickPaste.title", default: "Quick Paste"))
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.tr("quickPaste.behavior", default: "Quick paste removes formatting from copied text and turns images into plain text via OCR, then pastes it straight into the input field. The result depends on the selected content types, OCR settings, and Accessibility permission."))
                    Text(L10n.tr("quickPaste.scopeHelp", default: "Only selected types are converted. Images follow the OCR settings on the OCR page. Without Accessibility, plain text is prepared for manual ⌘V. Automatic pasting restores the original clipboard unless you copy something newer."))
                        .foregroundStyle(.tertiary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                CandidatePlacementPermissionRow(trusted: accessibilityTrusted)
            } header: {
                Text(L10n.tr("candidatePlacement.status", default: "Accessibility"))
            }
        }
        .formStyle(.grouped)
        .onAppear {
            accessibilityTrusted = SystemPasteSynthesizer.isAccessibilityTrusted
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityTrusted = SystemPasteSynthesizer.isAccessibilityTrusted
        }
    }
}

/// Accessibility status plus an explicit "open settings" button for candidate
/// caret placement. Only the explicit button invokes the system permission
/// flow; status refreshes when the app becomes active again.
struct CandidatePlacementPermissionRow: View {
    let trusted: Bool

    var body: some View {
        LabeledContent(L10n.tr("candidatePlacement.status", default: "Accessibility")) {
            HStack(spacing: 8) {
                Label(
                    trusted
                        ? L10n.tr("candidatePlacement.granted", default: "Granted")
                        : L10n.tr("candidatePlacement.notGranted", default: "Not granted"),
                    systemImage: trusted ? "checkmark.circle.fill" : "exclamationmark.circle"
                )
                .foregroundStyle(trusted ? Color.green : Color.secondary)
                .labelStyle(.titleAndIcon)
                if !trusted {
                    Button(L10n.tr("candidatePlacement.request", default: "Grant Access…")) {
                        SystemPasteSynthesizer.openAccessibilitySettings()
                    }
                }
            }
        }
    }
}
