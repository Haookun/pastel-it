import AppKit
import PasteItCore
import SwiftData

@MainActor
final class AppRuntime: NSObject {
    static let shared = AppRuntime()

    let settings: AppSettings
    let blobStore: BlobStore
    let historyStore: HistoryStore
    let searchService: SearchService
    let appState: AppState
    let pasteController: PasteController
    let pasteboardMonitor: PasteboardMonitor
    let hotkeyManager: HotkeyManager
    let quickPasteController: QuickPasteController
    let panelController: TimelinePanelController
    let detachedWindowController: ClipDetachedWindowController

    var state: AppState { appState }

    private var statusItem: NSStatusItem?
    private var keycapsIcon: MenuBarTartIcon?
    private var cmdCVFlashMonitor: CmdCVKeyFlashMonitor?
    private var didStart = false
    private let validationSession: AppValidationSession?

    private override init() {
        // An explicitly requested native UI review must use the same isolated
        // history and preferences as a validation launch, including shortcuts.
        let isUIReview = ProcessInfo.processInfo.arguments.contains("--ui-review")
        let validation = (ProcessInfo.processInfo.arguments.contains("--validation-session") || isUIReview)
            ? AppValidationSession() : nil
        validationSession = validation
        settings = validation?.settings ?? AppSettings()
        if let validation {
            historyStore = validation.historyStore
            blobStore = validation.historyStore.blobStore
        } else {
            blobStore = BlobStore()
            historyStore = HistoryStore(blobStore: blobStore, settings: settings)
        }
        settings.migratePrimaryAction()
        searchService = SearchService()
        appState = AppState(
            settings: settings,
            historyStore: historyStore,
            searchService: searchService
        )
        pasteController = PasteController(blobStore: blobStore)
        pasteboardMonitor = PasteboardMonitor(
            settings: settings,
            blobStore: blobStore,
            historyStore: historyStore
        )
        pasteController.onPasteboardMutation = { [pasteboardMonitor] changeCount in
            pasteboardMonitor.suppress(changeCount: changeCount)
        }
        panelController = TimelinePanelController(appState: appState, pasteController: pasteController)
        detachedWindowController = ClipDetachedWindowController(appState: appState)
        quickPasteController = QuickPasteController(settings: settings, pasteController: pasteController,
            panel: panelController, state: appState)
        hotkeyManager = HotkeyManager(
            defaults: validation?.defaults ?? .standard,
            showTimeline: { [panelController] in panelController.toggle(source: .hotkey) },
            editSelected: { [appState, panelController] in
                guard panelController.isVisible else { return false }
                return appState.beginEditingSelectedClip()
            },
            quickPaste: { [quickPasteController] in quickPasteController.perform() }
        )
        appState.panelController = panelController
        panelController.detachedWindowController = detachedWindowController
        detachedWindowController.timelinePanelController = panelController
        panelController.ingestBeforeShow = { [pasteboardMonitor] in
            await pasteboardMonitor.flushPendingCapture()
        }
        super.init()
    }

    func start() {
        guard !didStart else { return }
        didStart = true

        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--ui-review") {
            guard arguments.indices.contains(index + 1) else { NSApp.terminate(nil); return }
            let directory = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
            Task { @MainActor in
                do {
                    try await NativeUIReview().run(directory: directory)
                } catch {
                    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    try? String(describing: error).write(to: directory.appendingPathComponent("failure.txt"), atomically: true, encoding: .utf8)
                }
                NSApp.terminate(nil)
            }
            return
        }

        if validationSession == nil { DiagnosticLogs.shared.record(.applicationStarted) }
        historyStore.load()
        pasteboardMonitor.start()
        hotkeyManager.start()
        PermissionRestartMonitor.shared.start()
        detachedWindowController.start()
        configureStatusItem()
        startCmdCVFlashMonitor()
        if validationSession == nil {
            LaunchAtLoginManager.syncAtStartup(enabled: settings.launchAtLogin)
        }
        // Retain Sparkle updater for automatic background checks.
        _ = UpdateChecker.shared
        DispatchQueue.main.async { [panelController] in
            panelController.prewarm()
        }

        if !settings.hasCompletedOnboarding && !LanguageRepairController.shared.needsRepair {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [settings] in
                guard !settings.hasCompletedOnboarding else { return }
                OnboardingWindowController.shared.show(
                    settings: settings,
                    flow: .install,
                    source: "first_launch"
                )
            }
        } else if settings.seenWhatsNewContentVersion < AppSettings.currentWhatsNewContentVersion && !LanguageRepairController.shared.needsRepair {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [settings] in
                guard settings.hasCompletedOnboarding else { return }
                guard settings.seenWhatsNewContentVersion < AppSettings.currentWhatsNewContentVersion else { return }
                OnboardingWindowController.shared.show(
                    settings: settings,
                    flow: .update,
                    source: "update"
                )
            }
        }

        if validationSession != nil {
            DispatchQueue.main.async { [panelController] in panelController.show() }
        }
    }

    func stop() {
        if validationSession == nil { DiagnosticLogs.shared.record(.applicationStopped) }
        pasteboardMonitor.stop()
        hotkeyManager.stop()
        quickPasteController.stop()
        PermissionRestartMonitor.shared.stop()
        cmdCVFlashMonitor?.stop()
        cmdCVFlashMonitor = nil
        validationSession?.tearDown()
    }

    private func configureStatusItem() {
        let size = MenuBarTartIcon.preferredSize
        let item = NSStatusBar.system.statusItem(withLength: size.width)
        guard let button = item.button else {
            statusItem = item
            return
        }

        button.title = ""
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = "Pastel it！"
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.menu = nil

        // Drop any legacy keycaps subview from older builds / reconfigure.
        button.subviews.forEach { $0.removeFromSuperview() }

        let keycaps = MenuBarTartIcon()
        keycaps.onImageChange = { [weak button] image in
            button?.image = image
        }
        keycaps.publish()
        keycapsIcon = keycaps

        statusItem = item
        refreshStatusItem()
    }

    private func startCmdCVFlashMonitor() {
        let monitor = CmdCVKeyFlashMonitor(
            onCommandC: { [weak self] pressed in self?.keycapsIcon?.setPressed(pressed, for: .c) },
            onCommandV: { [weak self] pressed in self?.keycapsIcon?.setPressed(pressed, for: .v) }
        )
        monitor.start()
        cmdCVFlashMonitor = monitor
    }

    private func refreshStatusItem() {
        var tip = L10n.tr("menu.statusTooltip", default: "Pastel it！ — Clipboard history")
        tip += "\n" + L10n.tr("menu.statusClickHint", default: "Left-click: timeline · Right-click: menu")
        statusItem?.button?.toolTip = tip
    }

    /// Shared app menu used by the timeline's "…" button.
    func makeAppMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(makeShortcutMenuItem(title: L10n.tr("menu.openPaste", default: "Open Paste"), action: #selector(openTimeline), shortcut: .timeline))
        if settings.quickPasteEnabled {
            menu.addItem(makeShortcutMenuItem(
                title: L10n.tr("quickPaste.title", default: "Quick Paste"),
                action: #selector(quickPasteMenu), shortcut: .quickPaste
            ))
        }
        menu.addItem(NSMenuItem.separator())
        if historyStore.canUndoRemoval {
            let undoItem = makeMenuItem(
                title: L10n.tr("removal.undo", default: "Undo Removal"),
                action: #selector(undoRemoval), keyEquivalent: "z"
            )
            undoItem.toolTip = L10n.tr("removal.undoHelp", default: "Undo recent removals for 30 seconds (⌘Z).")
            menu.addItem(undoItem)
            menu.addItem(NSMenuItem.separator())
        }
        let pauseTitle = settings.capturePaused
            ? L10n.tr("menu.resumeCapture", default: "Resume Capture")
            : L10n.tr("menu.pauseCapture", default: "Pause Capture")
        menu.addItem(makeMenuItem(title: pauseTitle, action: #selector(togglePause), keyEquivalent: "t", shiftCommand: true))
        menu.addItem(makeMenuItem(title: L10n.tr("menu.preferences", default: "Preferences…"), action: #selector(openSettings), keyEquivalent: ","))
        if AppBrand.updatesEnabled {
            menu.addItem(makeMenuItem(
                title: L10n.tr("menu.checkUpdates", default: "Check for Updates…"),
                action: #selector(checkForUpdates),
                keyEquivalent: ""
            ))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: L10n.tr("menu.quit", default: "Quit Pastel it！"), action: #selector(quit), keyEquivalent: "q"))
        return menu
    }

    /// Pops the app menu below `view` (used by the timeline toolbar "…" button).
    func popUpAppMenu(relativeTo view: NSView) {
        let menu = makeAppMenu()
        let point = NSPoint(x: 0, y: view.bounds.height + 4)
        menu.popUp(positioning: nil, at: point, in: view)
    }

    // MARK: - Actions (also used by the SwiftUI toolbar Menu)

    func openTimelineAction() { openTimeline() }
    func togglePauseCaptureAction() { togglePause() }
    func openSettingsAction() { openSettings() }
    func quitAction() { quit() }

    var isCapturePaused: Bool { settings.capturePaused }

    private func makeShortcutMenuItem(title: String, action: Selector, shortcut: ShortcutAction) -> NSMenuItem {
        guard let binding = hotkeyManager.shortcuts[shortcut] else {
            let item = makeMenuItem(title: title, action: action, keyEquivalent: "")
            item.keyEquivalentModifierMask = []
            return item
        }
        let specials: [UInt32: String] = [36: "\r", 48: "\t", 49: " ", 51: "\u{8}",
            123: "\u{F702}", 124: "\u{F703}", 125: "\u{F701}", 126: "\u{F700}"]
        let functionEquivalent: String
        if binding.key.hasPrefix("F"), let number = Int(binding.key.dropFirst()), (1...20).contains(number),
           let scalar = UnicodeScalar(0xF704 + number - 1) {
            functionEquivalent = String(scalar)
        } else { functionEquivalent = "" }
        let equivalent = specials[binding.keyCode] ?? (binding.key.count == 1 ? binding.key.lowercased() : functionEquivalent)
        let item = makeMenuItem(title: title, action: action, keyEquivalent: equivalent)
        item.keyEquivalentModifierMask = binding.eventModifiers
        item.toolTip = binding.display
        return item
    }

    private func makeMenuItem(
        title: String,
        action: Selector?,
        keyEquivalent: String,
        shiftCommand: Bool = false,
        controlCommand: Bool = false,
        enabled: Bool = true
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = action == nil ? nil : self
        item.isEnabled = enabled
        if controlCommand, !keyEquivalent.isEmpty {
            item.keyEquivalentModifierMask = [.command, .control]
        } else if shiftCommand, !keyEquivalent.isEmpty {
            item.keyEquivalentModifierMask = [.command, .shift]
        }
        return item
    }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showStatusMenu()
        } else {
            panelController.toggle(source: .statusItem)
        }
    }

    /// Attach the menu to the status item and click it so macOS shows a normal
    /// status-bar menu (no popover caret from `popUp`).
    private func showStatusMenu() {
        guard let item = statusItem else { return }
        item.menu = makeAppMenu()
        item.button?.performClick(nil)
        // performClick blocks while the menu is open; clear afterward so the
        // next left-click opens Timeline instead of this menu.
        item.menu = nil
    }

    @objc private func toggleTimeline() {
        panelController.toggle(source: .hotkey)
    }

    @objc private func openTimeline() {
        panelController.show(source: .menu)
    }

    @objc private func quickPasteMenu() { quickPasteController.perform() }

    @objc private func togglePause() {
        settings.capturePaused.toggle()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show(appState: appState)
    }

    @objc private func checkForUpdates() {
        UpdateChecker.shared.checkForUpdates(source: "menu")
    }

    @objc private func undoRemoval() { appState.undoLastRemoval() }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
