import AppKit
import SwiftUI
import PasteItCore

extension ShortcutAction {
    var title: String {
        switch self {
        case .timeline: L10n.tr("menu.openPaste", default: "Open Paste")
        case .stack: L10n.tr("stack.open", default: "Open Paste Stack")
        case .plainPaste: L10n.tr("menu.pastePlain", default: "Paste Without Formatting")
        case .quickPaste: L10n.tr("quickPaste.title", default: "Quick Paste")
        }
    }
}

struct ShortcutSettingsView: View {
    @ObservedObject var manager: HotkeyManager
    var actions: [ShortcutAction] = ShortcutAction.allCases
    var showsReset = true
    @State private var recording: ShortcutAction?

    var body: some View {
        ForEach(actions, id: \.self) { action in
            LabeledContent(action.title) {
                Button {
                    manager.clearError()
                    manager.beginRecording()
                    recording = action
                } label: {
                    Text(manager.shortcuts[action]?.display ?? "")
                        .frame(minWidth: 56, minHeight: 18)
                }
                .font(.system(.body, design: .monospaced))
                .accessibilityLabel(action.title + ": " + (manager.shortcuts[action]?.display ?? L10n.tr("shortcuts.unassigned", default: "Not assigned")))
                .help(L10n.tr("shortcuts.edit", default: "Click to change this shortcut"))
            }
        }
        if showsReset {
            Button(L10n.tr("shortcuts.reset", default: "Reset All Shortcuts to Defaults")) {
                manager.resetDefaults()
            }
            .disabled(manager.shortcuts == .defaults)
        }
        if let error = manager.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        Text(L10n.tr("shortcuts.help", default: "Click a shortcut, then press a new combination. Changes take effect immediately and are saved on this Mac."))
            .font(.caption)
            .foregroundStyle(.secondary)
        .sheet(item: $recording, onDismiss: { manager.endRecording() }) { action in
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.tr("shortcuts.recordTitle", default: "Change Shortcut"))
                    .font(.headline)
                Text(action.title)
                Text(L10n.tr("shortcuts.recordHelp", default: "Press a key with Command, Control, or Option. Press Backspace to clear, or Escape to cancel."))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                ShortcutCapture { event in
                    if event.keyCode == 53 { recording = nil; return }
                    if event.keyCode == 51,
                       event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
                        if manager.clear(action) { recording = nil }
                        return
                    }
                    if manager.set(ShortcutBinding(event: event), for: action) { recording = nil }
                }
                .frame(height: 44)
                if let error = manager.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    Spacer()
                    Button(L10n.tr("common.cancel", default: "Cancel")) { recording = nil }
                }
            }
            .padding(24)
            .frame(width: 420)
        }
        .onDisappear { recording = nil; manager.endRecording() }
    }
}

private struct ShortcutCapture: NSViewRepresentable {
    var onKey: (NSEvent) -> Void
    func makeNSView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onKey = onKey
        return view
    }
    func updateNSView(_ view: CaptureView, context: Context) { view.onKey = onKey }

    final class CaptureView: NSView {
        var onKey: ((NSEvent) -> Void)?
        override var acceptsFirstResponder: Bool { true }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
            setAccessibilityRole(.textField)
            setAccessibilityLabel(L10n.tr("shortcuts.listening", default: "Waiting for shortcut…"))
        }
        override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
        override func keyDown(with event: NSEvent) { onKey?(event) }
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            guard window?.firstResponder === self else { return false }
            onKey?(event)
            return true
        }
        override func draw(_ dirtyRect: NSRect) {
            NSColor.controlBackgroundColor.setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
            let text = L10n.tr("shortcuts.listening", default: "Waiting for shortcut…")
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium), .foregroundColor: NSColor.secondaryLabelColor]
            let size = text.size(withAttributes: attributes)
            text.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2), withAttributes: attributes)
        }
    }
}
