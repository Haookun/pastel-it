import AppKit
import PasteItCore

@MainActor
final class QuickPasteController {
    private let settings: AppSettings
    private let pasteController: PasteController
    private let stack: PasteStackController
    private let panel: TimelinePanelController
    private let state: AppState
    private var task: Task<Void, Never>?

    init(settings: AppSettings, pasteController: PasteController, stack: PasteStackController,
         panel: TimelinePanelController, state: AppState) {
        self.settings = settings
        self.pasteController = pasteController
        self.stack = stack
        self.panel = panel
        self.state = state
    }

    func stop() { task?.cancel() }

    @discardableResult
    func perform() -> Bool {
        guard settings.quickPasteEnabled, task == nil else { return false }
        let changeCount = pasteController.pasteboardChangeCount
        let destination = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let scope = settings.quickPasteScope
        let configuration = settings.ocrConfiguration
        task = Task { @MainActor in
            defer { task = nil }
            guard let plain = await pasteController.quickPasteText(
                scope: scope, configuration: configuration, ignoredTypes: settings.ignoredPasteboardTypes
            ), !plain.isEmpty else {
                state.setStatus(L10n.tr("quickPaste.noContent", default: "No enabled content to convert; clipboard unchanged"))
                return
            }
            guard !Task.isCancelled, settings.quickPasteEnabled,
                  settings.quickPasteScope == scope, settings.ocrConfiguration == configuration else { return }
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                if panel.isVisible { panel.hide { continuation.resume() } }
                else { continuation.resume() }
            }
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled, settings.quickPasteEnabled,
                  settings.quickPasteScope == scope, settings.ocrConfiguration == configuration,
                  pasteController.pasteboardChangeCount == changeCount,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == destination else {
                state.setStatus(L10n.tr("quickPaste.changed", default: "Clipboard or destination changed; quick paste cancelled"))
                return
            }
            let snapshot = pasteController.snapshotGeneralPasteboard()
            stack.suspendPasteIntercept()
            defer { stack.resumePasteIntercept() }
            guard pasteController.writePlainTextToGeneralPasteboard(plain) else { return }
            let writtenCount = pasteController.pasteboardChangeCount
            guard SystemPasteSynthesizer.isAccessibilityTrusted else {
                stack.ensureAccessibilityIfNeeded()
                state.setStatus(L10n.tr("quickPaste.manual", default: "Plain text ready. Press ⌘V, or enable Accessibility for automatic pasting."))
                return
            }
            // Restore only our temporary write, never a newer copy made by the user.
            defer {
                if pasteController.pasteboardChangeCount == writtenCount, let snapshot {
                    _ = pasteController.restoreGeneralPasteboard(snapshot)
                }
            }
            try? await Task.sleep(nanoseconds: SystemPasteSynthesizer.writeSettleNanoseconds)
            guard !Task.isCancelled, pasteController.pasteboardChangeCount == writtenCount,
                  settings.quickPasteEnabled, SystemPasteSynthesizer.isAccessibilityTrusted,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == destination else { return }
            await SystemPasteSynthesizer.postCommandVAsync()
            try? await Task.sleep(nanoseconds: SystemPasteSynthesizer.targetPasteNanoseconds)
            state.setStatus(L10n.tr("quickPaste.done", default: "Pasted as plain text"))
        }
        return true
    }
}
