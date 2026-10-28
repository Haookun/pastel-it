import AppKit
import QuartzCore
import SwiftUI
import Combine
import PasteItCore

enum TimelinePanelOpenSource: String {
    case hotkey
    case statusItem = "status_item"
    case menu
}

private enum PanelAnimation {
    case none
    case showing
    case hiding
}

@MainActor
final class TimelinePanelController: NSObject, NSWindowDelegate, ObservableObject {
    @Published private var requestedCandidatePage = 0
    @Published private(set) var candidateSelectedID: UUID?
    @Published private(set) var candidateMessage: String?
    @Published private(set) var candidatePlacementNotice: String?
    @Published private(set) var candidatePreviewDismissRequest = UUID()
    private var candidateAnchor: CGRect?
    private var candidateFallbackPoint = CGPoint.zero
    private let candidateAnchorProvider: (@MainActor (pid_t) async -> CGRect?)?
    private var candidateKeyMonitor: Any?
    private var candidateActivationTask: Task<Void, Never>?
    private var candidateDestination: NSRunningApplication?
    private var settingsObservation: AnyCancellable?
    private var lastPresentationStyle: ClipboardPresentationStyle?

    private let appState: AppState
    private let pasteController: PasteController
    private var panel: NSPanel?
    private lazy var removalToastController = RemovalToastPanelController(appState: appState)
    private var globalOutsideClickMonitor: Any?
    private var localOutsideClickMonitor: Any?
    /// Slide-in / slide-out are distinct so hide can interrupt an in-flight show
    /// instead of no-oping and firing callers' completions immediately.
    private var panelAnimation: PanelAnimation = .none
    /// Bumped whenever a new show/hide animation starts; stale completions no-op.
    private var animationGeneration = 0
    private var pendingHideCompletions: [@Sendable () -> Void] = []
    /// True while we await clipboard ingest before the slide-in.
    private var isPreparingShow = false
    private var showRequestID = UUID()
    var onShow: (() -> Void)?
    /// Ingest any pending clipboard change so ⇧⌘C right after copy shows the new card.
    var ingestBeforeShow: (() async -> Void)?
    /// Set by AppRuntime so outside-click dismiss can ignore detached preview windows.
    weak var detachedWindowController: ClipDetachedWindowController?

    static let panelHeight: CGFloat = 380
    private let bottomInset: CGFloat = 12
    private let animationDuration: CFTimeInterval = 0.28

    init(appState: AppState, pasteController: PasteController, candidateAnchorProvider: (@MainActor (pid_t) async -> CGRect?)? = nil) {
        self.candidateAnchorProvider = candidateAnchorProvider
        self.appState = appState
        self.pasteController = pasteController
        super.init()
        lastPresentationStyle = appState.settings.clipboardPresentationStyle
        settingsObservation = appState.settings.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.refreshPresentationStyle() }
        }
    }

    func toggle(source: TimelinePanelOpenSource) {
        if isPreparingShow || panel?.isVisible == true {
            isPreparingShow = false
            hide()
        } else {
            show(source: source)
        }
    }

    var isVisible: Bool {
        panel?.isVisible == true
    }

    /// Build the hosting view and force one off-screen layout so the first ⇧⌘C isn't a cold mount.
    func prewarm() {
        guard panel == nil else { return }
        let panel = makePanel()
        self.panel = panel
        let finalFrame = targetFrame(for: panel)
        var parked = finalFrame
        parked.origin.y -= finalFrame.height + 80
        panel.alphaValue = 0
        panel.setFrame(parked, display: false)
        panel.orderFrontRegardless()
        panel.displayIfNeeded()
        panel.orderOut(nil)
        panel.alphaValue = 1
    }

    /// Screen frame of the floating timeline panel (bubble anchors above this).
    var panelFrame: NSRect? {
        panel?.frame
    }

    /// Clears first responder so space-bar / shortcuts aren't eaten by the search field.
    func resignFirstResponder() {
        panel?.makeFirstResponder(nil)
    }

    func restoreKeyFocus() {
        guard let panel, panel.isVisible else { return }
        panel.makeKey()
        panel.makeFirstResponder(nil)
    }

    func show(source: TimelinePanelOpenSource = .menu) {
        // Ignore re-entrant show; hide-in-flight keeps sliding out (toggle will
        // see isVisible and call hide again, which just waits for that animation).
        guard panelAnimation == .none else { return }
        if isPreparingShow { return }
        isPreparingShow = true
        let requestID = UUID()
        showRequestID = requestID
        let destination = NSWorkspace.shared.frontmostApplication
        let fallbackPoint = NSEvent.mouseLocation
        let desktopTop = NSScreen.screens.first?.frame.maxY ?? 0
        onShow?()
        Task { @MainActor in
            if appState.settings.clipboardPresentationStyle == .candidateBar {
                let anchor: CGRect?
                if let pid = destination?.processIdentifier {
                    if let candidateAnchorProvider { anchor = await candidateAnchorProvider(pid) }
                    else { anchor = await CaretLocator.capture(processID: pid, primaryScreenTop: desktopTop) }
                } else { anchor = nil }
                guard self.isPreparingShow, self.showRequestID == requestID else { return }
                self.candidateAnchor = anchor
                self.candidateFallbackPoint = fallbackPoint
                self.candidatePlacementNotice = anchor == nil ? L10n.tr("candidateBar.locationFallback", default: "Caret position unavailable. Showing near the pointer; Accessibility may be required.") : nil
            }
            self.candidateDestination = destination
            await ingestBeforeShow?()
            guard self.isPreparingShow, self.showRequestID == requestID else { return }
            self.isPreparingShow = false
            // Store add() publishes on the next main turn. Pull the new clip in
            // now so the slide-in doesn't paint the old first card, then shuffle.
            self.appState.absorbNewestClipBeforePanelShow()
            self.performShow(source: source)
        }
    }

    func showPreservingContext() {
        guard panelAnimation == .none else { return }
        performShow(source: .menu, preserveContext: true)
    }

    private func performShow(source: TimelinePanelOpenSource, preserveContext: Bool = false) {
        if !preserveContext {
            requestedCandidatePage = 0
            candidateMessage = nil
            candidateSelectedID = candidateItems.first?.id
        }
        let panel = self.panel ?? makePanel()
        self.panel = panel
        if !preserveContext && !appState.isReadyForInstantShow() {
            appState.resetFiltersForPanelShow()
        }

        updatePanelChrome(panel)
        let finalFrame = targetFrame(for: panel)
        let startFrame: NSRect
        let candidate = appState.settings.clipboardPresentationStyle == .candidateBar
        if candidate {
            startFrame = finalFrame
        } else if let screen = screenForCurrentFocus() {
            startFrame = panelSlideOffscreenFrame(from: finalFrame, screen: screen)
        } else {
            var fallback = finalFrame
            fallback.origin.y -= finalFrame.height
            startFrame = fallback
        }
        panel.setFrame(startFrame, display: false)
        panel.alphaValue = candidate ? 0 : 1

        // nonactivatingPanel + orderFrontRegardless keeps the previous app focused
        // so the user can immediately ⌘V after staging a clip (Paste-like).
        // makeKey() still allows the search field to accept typing.
        panel.orderFrontRegardless()
        panel.makeKey()
        // Prevent SwiftUI from parking first-responder in the search field.
        panel.makeFirstResponder(nil)
        startOutsideClickMonitoring()

        animationGeneration += 1
        let generation = animationGeneration
        panelAnimation = .showing
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = candidate ? 0.12 : animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(finalFrame, display: true)
            panel.animator().alphaValue = 1
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, generation == self.animationGeneration else { return }
                self.panelAnimation = .none
                self.resizeForPresentation()
                // Defer out of the display-cycle flush — mutating @Published
                // mid-layout was crashing under exclusivity checking.
                DispatchQueue.main.async {
                    guard generation == self.animationGeneration else { return }
                    self.panel?.makeFirstResponder(nil)
                    self.appState.searchBlurRequest += 1
                    self.appState.warmTabCaches()
                }
            }
        })
    }

    private var preserveContextForHide = false

    func hide(preserveContext: Bool = false, completion: (@Sendable () -> Void)? = nil) {
        appState.removalFeedback.dismiss()
        removalToastController.hide(animated: false)
        if panelAnimation != .hiding { preserveContextForHide = preserveContext }
        isPreparingShow = false
        showRequestID = UUID()
        if let completion {
            pendingHideCompletions.append(completion)
        }

        switch panelAnimation {
        case .hiding:
            // Already sliding out — wait for that animation, don't fake-complete.
            return
        case .showing:
            beginHide()
        case .none:
            guard let panel, panel.isVisible else {
                stopOutsideClickMonitoring()
                flushHideCompletions()
                return
            }
            beginHide()
        }
    }

    private func beginHide() {
        candidatePreviewDismissRequest = UUID()
        guard let panel else {
            panelAnimation = .none
            flushHideCompletions()
            return
        }

        // Preview bubble is timeline-anchored; dismiss it with the panel.
        if appState.previewClip != nil {
            appState.dismissPreview()
        }
        stopOutsideClickMonitoring()

        animationGeneration += 1
        let generation = animationGeneration
        panelAnimation = .hiding

        let endFrame: NSRect
        if appState.settings.clipboardPresentationStyle == .candidateBar {
            endFrame = panel.frame
        } else if let screen = panel.screen ?? screenForCurrentFocus() {
            endFrame = panelSlideOffscreenFrame(from: panel.frame, screen: screen)
        } else {
            var fallback = panel.frame
            fallback.origin.y -= fallback.height
            endFrame = fallback
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            // From the current frame, so an interrupted slide-in reverses in place.
            panel.animator().setFrame(endFrame, display: true)
            // Fade alongside the slide: when a display below forces the slide to
            // clamp at the screen edge, the fade carries the dismissal.
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, generation == self.animationGeneration else { return }
                panel.orderOut(nil)
                panel.alphaValue = 1
                self.panelAnimation = .none
                if !self.preserveContextForHide { self.appState.prepareForNextPanelShow() }
                self.flushHideCompletions()
            }
        })
    }

    private func flushHideCompletions() {
        let completions = pendingHideCompletions
        pendingHideCompletions.removeAll()
        for completion in completions {
            completion()
        }
    }

    private func makePanel() -> NSPanel {
        let contentView = ClipboardPanelContent(appState: appState, pasteController: pasteController, controller: self)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.sizingOptions = []

        let panel = FloatingTimelinePanel(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: Self.panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.onCandidateKey = { [weak self, weak panel] event in
            guard let self, panel?.isVisible == true else { return false }
            return self.handleCandidateKey(event)
        }
        panel.title = "Pastel it！"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.acceptsMouseMovedEvents = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentViewController = hostingController
        panel.delegate = self
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isOpaque = false

        // AppKit-level continuous clip: SwiftUI glass alone does not clear the
        // rectangular hosting surface, which shows as opaque corner "ears".
        PanelCornerMask.apply(to: hostingController.view)
        PanelCornerMask.apply(to: panel.contentView)
        removalToastController.attach(to: panel)

        return panel
    }

    private func updatePanelChrome(_ panel: NSPanel) {
        let candidate = appState.settings.clipboardPresentationStyle == .candidateBar
        panel.hasShadow = candidate
        panel.contentView?.layer?.cornerRadius = candidate ? 12 : PanelCornerMask.radius
        panel.contentViewController?.view.layer?.cornerRadius = candidate ? 12 : PanelCornerMask.radius
    }

    private func targetFrame(for panel: NSPanel) -> NSRect {
        let candidate = appState.settings.clipboardPresentationStyle == .candidateBar
        let point = candidateAnchor.map { CGPoint(x: $0.midX, y: $0.midY) } ?? candidateFallbackPoint
        let screen = candidate ? (NSScreen.screens.first { $0.frame.contains(point) } ?? screenForCurrentFocus()) : screenForCurrentFocus()
        guard let screen else { return panel.frame }
        let visibleFrame = screen.visibleFrame
        let width = min(candidate ? 420 : 1120, max(1, visibleFrame.width - 32))
        let candidateHeight: CGFloat = candidatePageItems.isEmpty ? 153 : CandidateBarView.topBarHeight + 1 + CGFloat(candidatePageItems.count) * CandidateBarView.rowHeight
        let height = min(candidate ? candidateHeight + (candidateMessage == nil ? 0 : 44) : Self.panelHeight, max(1, visibleFrame.height - 24))
        if candidate {
            let anchor = candidateAnchor ?? CGRect(origin: candidateFallbackPoint, size: .zero)
            return CandidatePanelPlacement.frame(anchor: anchor, size: CGSize(width: width, height: height), visibleFrame: visibleFrame)
        }
        return NSRect(x: visibleFrame.midX - width / 2, y: visibleFrame.minY + bottomInset, width: width, height: height)
    }

    var candidateItems: [ClipItem] {
        // Candidate mode always shows recent history, independent of timeline
        // search, folders or a previously retained type filter.
        appState.historyStore.clips.filter { !$0.isHiddenFromTimeline }
    }

    var candidatePageIndex: Int {
        CandidatePagination.clampedPage(requestedCandidatePage, itemCount: candidateItems.count)
    }

    var candidatePageCount: Int { CandidatePagination.pageCount(itemCount: candidateItems.count) }

    var candidatePageItems: [ClipItem] {
        let items = candidateItems
        return Array(items[CandidatePagination.range(page: requestedCandidatePage, itemCount: items.count)])
    }

    func nextCandidatePage() { changeCandidatePage(by: 1) }
    func previousCandidatePage() { changeCandidatePage(by: -1) }

    private func changeCandidatePage(by delta: Int) {
        let next = CandidatePagination.clampedPage(candidatePageIndex + delta, itemCount: candidateItems.count)
        guard next != candidatePageIndex else { return }
        requestedCandidatePage = next
        candidateSelectedID = candidatePageItems.first?.id
        candidateMessage = nil
        resizeForPresentation()
    }

    private func refreshPresentationStyle() {
        let style = appState.settings.clipboardPresentationStyle
        guard style != lastPresentationStyle else { return }
        lastPresentationStyle = style
        requestedCandidatePage = 0
        candidateMessage = nil
        candidateSelectedID = candidateItems.first?.id
        appState.dismissPreview()
        objectWillChange.send()
        resizeForPresentation()
    }

    private func resizeForPresentation() {
        guard let panel, panel.isVisible, panelAnimation == .none else { return }
        updatePanelChrome(panel)
        panel.setFrame(targetFrame(for: panel), display: true)
        panel.makeFirstResponder(nil)
    }

    @discardableResult
    func handleCandidateKey(_ event: NSEvent) -> Bool {
        guard appState.settings.clipboardPresentationStyle == .candidateBar,
              let action = CandidateKeyAction.resolve(keyCode: event.keyCode,
                characters: event.charactersIgnoringModifiers ?? "", modifiers: ShortcutBinding(event: event).modifiers) else { return false }
        let items = candidatePageItems
        switch action {
        case .choose(let index):
            if items.indices.contains(index) { activateCandidate(items[index]) }
        case .activate:
            if let item = items.first(where: { $0.id == candidateSelectedID }) ?? items.first { activateCandidate(item) }
        case .nextPage: nextCandidatePage()
        case .previousPage: previousCandidatePage()
        case .close: hide()
        case .move(let delta):
            let current = items.firstIndex { $0.id == candidateSelectedID }
            if let index = CandidateKeyAction.movedIndex(current: current, delta: delta, count: items.count) {
                candidateSelectedID = items[index].id
            }
        }
        return true
    }

    func activateCandidate(_ item: ClipItem) {
        guard candidateActivationTask == nil else { return }
        candidateSelectedID = item.id
        appState.selectOnly(item.id)
        candidateMessage = nil
        let target = candidateDestination ?? NSWorkspace.shared.frontmostApplication
        let shouldPaste = appState.settings.timelinePrimaryAction.shouldPaste
        candidateActivationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.candidateActivationTask = nil }
            guard await self.pasteController.copyToPasteboardAsync(item) else {
                self.candidateMessage = L10n.tr("action.writeFailed", default: "Could not copy this clip. Its content or attachment may be unavailable. Restore the file, then retry.")
                self.resizeForPresentation()
                return
            }
            let writtenCount = self.pasteController.pasteboardChangeCount
            if shouldPaste && !SystemPasteSynthesizer.isAccessibilityTrusted {
                self.candidateMessage = L10n.tr("action.copiedManual", default: "Copied. Return to your app and press ⌘V. Enable Accessibility for direct paste.")
                self.resizeForPresentation()
                return
            }
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                self.hide(preserveContext: true) { continuation.resume() }
            }
            if shouldPaste {
                if NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier,
                   let target, target.processIdentifier != ProcessInfo.processInfo.processIdentifier, !target.isTerminated {
                    target.activate(options: [])
                }
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled, SystemPasteSynthesizer.isAccessibilityTrusted,
                      let target, !target.isTerminated,
                      target.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                      NSWorkspace.shared.frontmostApplication?.processIdentifier == target.processIdentifier,
                      self.pasteController.pasteboardChangeCount == writtenCount else {
                    self.candidateMessage = L10n.tr("action.focusChanged", default: "Paste stopped because the destination or permission changed. Focus your destination and try the remaining clips again.")
                    self.showPreservingContext()
                    return
                }
                await SystemPasteSynthesizer.pasteWrittenItem()
            }
            self.appState.promoteAccessedClip(item, scroll: false)
            self.appState.setStatus(L10n.tr("action.copied", default: "Copied to Clipboard"))
        }
    }

    private func screenForCurrentFocus() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main
    }

    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        globalOutsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            Task { @MainActor in
                self?.hideIfMouseIsOutsidePanel()
            }
        }

        candidateKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible,
                  event.window?.parent === panel,
                  self.appState.settings.clipboardPresentationStyle == .candidateBar else { return event }
            return self.handleCandidateKey(event) ? nil : event
        }

        localOutsideClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self else { return event }

            if self.shouldIgnoreOutsideClick(for: event) {
                return event
            }

            // Peek matrix: clicks on the timeline while a bubble is open.
            // Same card / chrome → dismiss; other card → let selection retarget the bubble.
            if self.appState.previewClip != nil,
               event.window === self.panel,
               event.type == .leftMouseDown {
                self.handlePreviewOpenPanelClick()
                return event
            }

            if event.window !== self.panel {
                self.hide()
            }
            return event
        }
    }

    /// Resolve Space-preview dismiss vs retarget from a click on the timeline panel.
    private func handlePreviewOpenPanelClick() {
        let point = NSEvent.mouseLocation
        if let hitID = ClipCardFrameRegistry.cardID(atScreenPoint: point) {
            if hitID == appState.previewClip?.id {
                appState.dismissPreview()
            }
            // Different card: SwiftUI card tap selects → syncPreviewToSelection retargets.
            return
        }
        // Toolbar / blank / gaps — leave the peeked context.
        appState.dismissPreview()
    }

    private func stopOutsideClickMonitoring() {
        if let candidateKeyMonitor { NSEvent.removeMonitor(candidateKeyMonitor) }
        candidateKeyMonitor = nil
        if let globalOutsideClickMonitor {
            NSEvent.removeMonitor(globalOutsideClickMonitor)
        }
        if let localOutsideClickMonitor {
            NSEvent.removeMonitor(localOutsideClickMonitor)
        }
        globalOutsideClickMonitor = nil
        localOutsideClickMonitor = nil
    }

    private func hideIfMouseIsOutsidePanel() {
        guard let panel, panel.isVisible else { return }
        let mouse = NSEvent.mouseLocation
        if panel.frame.contains(mouse) { return }
        if removalToastController.visibleFrame?.contains(mouse) == true { return }
        // Clicks on detached preview should not dismiss the timeline.
        // Only count *visible* windows — ordered-out panels keep their last frame and would
        // otherwise swallow outside clicks (especially a centered preview bubble).
        if let detached = detachedWindowController {
            for window in NSApp.windows where detached.owns(window) && window.isVisible && window.frame.contains(mouse) {
                return
            }
        }
        hide()
    }

    /// Ignore outside-dismiss when the click lands on a detached preview window
    /// or any sheet/child of the timeline panel.
    private func shouldIgnoreOutsideClick(for event: NSEvent) -> Bool {
        guard let panel else { return false }
        if let window = event.window, detachedWindowController?.owns(window) == true {
            return true
        }
        guard let window = event.window else { return false }
        if window === panel { return false }
        if window.sheetParent === panel { return true }
        if panel.sheets.contains(where: { $0 === window }) { return true }
        if window.parent === panel { return true }
        return false
    }
}

private final class FloatingTimelinePanel: NSPanel {
    var onCandidateKey: ((NSEvent) -> Bool)?

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, onCandidateKey?(event) == true { return }
        super.sendEvent(event)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
