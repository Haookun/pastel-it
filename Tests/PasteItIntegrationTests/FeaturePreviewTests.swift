import AppKit
import SwiftUI
import Testing
import PasteItCore
@testable import PasteIt

@MainActor
@Suite("Synthetic feature windows", .serialized)
struct FeaturePreviewTests {
    @Test func rendersTimelineAndOCRPreferencesWithSyntheticData() async throws {
        let name = "PasteIt-Feature-Preview-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        let settings = AppSettings(defaults: defaults)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteIt-Feature-\(UUID())")
        let store = HistoryStore(ephemeralBlobRoot: root, settings: settings)
        let state = AppState(settings: settings, historyStore: store, searchService: SearchService())
        let board = NSPasteboard.withUniqueName()
        let paste = PasteController(blobStore: store.blobStore, pasteboard: board)
        let keys = HotkeyManager(defaults: defaults, showTimeline: {}, togglePasteStack: {},
                                 pastePlain: { false }, editSelected: { false })
        for index in 0..<30 {
            store.context.insert(ClipItem(createdAt: Date().addingTimeInterval(Double(-index * 3600)),
                title: "Synthetic note \(index)", plainText: "合成记录 \(index) · Synthetic text · テスト",
                primaryType: .text, pasteboardTypes: [], contentHash: "preview-\(index)"))
        }
        try store.context.save()
        store.refresh()
        await state.awaitSearchResults()
        state.selectFirst()
        let timeline = NSHostingController(rootView: TimelineView(appState: state, pasteController: paste)
            .frame(width: 1120, height: TimelinePanelController.panelHeight))
        let preferences = NSHostingController(rootView: OCRSettingsView(settings: settings, manager: keys)
            .frame(width: 760, height: 720))
        let window = NSWindow(contentRect: NSRect(x: 100, y: 150, width: 1120, height: TimelinePanelController.panelHeight),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Paste It — Synthetic Feature Preview"
        window.isReleasedWhenClosed = false
        let isInteractive = ProcessInfo.processInfo.environment["PASTEIT_FEATURE_PREVIEW_DIR"] != nil
        let policy = NSApp.activationPolicy()
        if isInteractive { NSApp.setActivationPolicy(.regular) }
        defer {
            window.orderOut(nil)
            if isInteractive { NSApp.setActivationPolicy(policy) }
            board.releaseGlobally()
            store.destroyEphemeralFiles()
            defaults.removePersistentDomain(forName: name)
        }
        window.contentViewController = timeline
        window.orderFrontRegardless()
        if isInteractive { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
        try await Task.sleep(for: .milliseconds(300))
        timeline.view.layoutSubtreeIfNeeded()
        #expect(timeline.view.bounds.height >= 380)

        let directory = ProcessInfo.processInfo.environment["PASTEIT_FEATURE_PREVIEW_DIR"].map { URL(fileURLWithPath: $0) }
        if let directory {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let identity: [String: Int] = ["pid": Int(ProcessInfo.processInfo.processIdentifier), "window": window.windowNumber]
            try JSONSerialization.data(withJSONObject: identity).write(to: directory.appendingPathComponent("window.json"))
            try capture(timeline.view, to: directory.appendingPathComponent("timeline.png"))
            // A bounded manual-inspection window; normal test runs never wait here.
            await waitForInspection(in: directory, stage: "timeline")
        }
        window.contentViewController = preferences
        window.setContentSize(NSSize(width: 760, height: 720))
        try await Task.sleep(for: .milliseconds(300))
        preferences.view.layoutSubtreeIfNeeded()
        #expect(preferences.view.bounds.width >= 680)
        if let directory {
            try capture(preferences.view, to: directory.appendingPathComponent("ocr-settings.png"))
            await waitForInspection(in: directory, stage: "ocr")
        }
    }

    private func capture(_ view: NSView, to url: URL) throws {
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        try #require(bitmap.representation(using: .png, properties: [:])).write(to: url)
    }

    private func waitForInspection(in directory: URL, stage: String) async {
        for _ in 0..<180 {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent("advance-\(stage)").path) { break }
            try? await Task.sleep(for: .milliseconds(500))
        }
    }
}
