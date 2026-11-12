import AppKit
import Foundation
import Testing
import PasteItCore
@testable import PasteIt

private actor DelayedCandidateOCR {
    private(set) var started = false
    private var continuation: CheckedContinuation<String?, Never>?

    func recognize() async -> String? {
        started = true
        return await withCheckedContinuation { continuation = $0 }
    }

    func finish() {
        continuation?.resume(returning: "Synthetic newly recognized text")
        continuation = nil
    }
}

@MainActor
@Suite("Candidate on-demand OCR", .serialized)
struct CandidateOnDemandOCRTests {
    @Test(arguments: [false, true])
    func newerClipboardOrDismissalCancelsPendingCopy(changeClipboard: Bool) async throws {
        let name = "PastelIt-OCR-Click-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        let settings = AppSettings(defaults: defaults)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteItEphemeral-OCR-Click-\(UUID())")
        let store = HistoryStore(ephemeralBlobRoot: root, settings: settings)
        let board = NSPasteboard.withUniqueName()
        defer {
            board.releaseGlobally()
            store.destroyEphemeralFiles()
            defaults.removePersistentDomain(forName: name)
        }
        let path = try store.blobStore.store(data: Data([1, 2, 3]), preferredExtension: "png", id: UUID())
        let item = ClipItem(title: "Synthetic image", primaryType: .image, pasteboardTypes: [],
                            blobRelativePath: path, contentHash: "delayed-ocr")
        store.context.insert(item)
        store.refresh()
        let gate = DelayedCandidateOCR()
        let writer = PasteController(blobStore: store.blobStore, pasteboard: board,
                                     recognizeImageText: { _, _ in await gate.recognize() })
        let state = AppState(settings: settings, historyStore: store, searchService: SearchService())
        let panel = TimelinePanelController(appState: state, pasteController: writer)
        state.panelController = panel
        board.setString("Synthetic before recognition", forType: .string)
        panel.activateCandidate(item, action: .copyPlainText)
        for _ in 0..<100 {
            if await gate.started { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        let started = await gate.started
        #expect(started)
        if changeClipboard {
            board.clearContents()
            board.setString("Synthetic newer copy", forType: .string)
        } else {
            panel.hide()
        }
        let expectedCount = board.changeCount
        let expectedText = board.string(forType: .string)
        await gate.finish()
        // Give the suspended action time to resume; observe the board throughout.
        for _ in 0..<25 {
            try await Task.sleep(for: .milliseconds(10))
            #expect(board.changeCount == expectedCount)
        }
        #expect(board.string(forType: .string) == expectedText)
    }
}
