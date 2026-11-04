import AppKit
import Foundation
import Testing
import PasteItCore
@testable import PasteIt

@MainActor
struct ClipboardPresentationTests {
    @Test func presentationPersistsAndUnknownValueFallsBackWithoutChangingPrimaryAction() throws {
        let name = "PastelIt-Style-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.clipboardPresentationStyle == .candidateBar)
        settings.clipboardPresentationStyle = .timeline
        #expect(AppSettings(defaults: defaults).clipboardPresentationStyle == .timeline)
        let primary = settings.timelinePrimaryAction
        settings.clipboardPresentationStyle = .candidateBar
        #expect(AppSettings(defaults: defaults).clipboardPresentationStyle == .candidateBar)
        #expect(settings.timelinePrimaryAction == primary)
        defaults.set("unknown-future-value", forKey: "clipboardPresentationStyle")
        #expect(AppSettings(defaults: defaults).clipboardPresentationStyle == .candidateBar)
    }
    @Test func candidateNumbersUseTheSuppressedWriterAndIgnoreTimelineFilters() async throws {
        let name = "PastelIt-Candidate-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteItEphemeral-Candidate-\(UUID())")
        let board = NSPasteboard.withUniqueName()
        let settings = AppSettings(defaults: defaults)
        settings.clipboardPresentationStyle = .candidateBar
        settings.timelinePrimaryAction = .copyOnly
        let store = HistoryStore(ephemeralBlobRoot: root, settings: settings)
        defer {
            board.releaseGlobally()
            store.destroyEphemeralFiles()
            defaults.removePersistentDomain(forName: name)
        }
        for index in 0..<23 {
            store.context.insert(ClipItem(createdAt: Date().addingTimeInterval(Double(-index)), title: "Synthetic \(index)",
                                           plainText: "Synthetic \(index)", primaryType: .text, pasteboardTypes: [], contentHash: "candidate-\(index)"))
        }
        try store.context.save()
        store.refresh()
        let state = AppState(settings: settings, historyStore: store, searchService: SearchService())
        state.query = "no-such-synthetic-text"
        let writer = PasteController(blobStore: store.blobStore, pasteboard: board)
        var suppressed: [Int] = []
        writer.onPasteboardMutation = { suppressed.append($0) }
        let panel = TimelinePanelController(appState: state, pasteController: writer)
        state.panelController = panel
        #expect(panel.candidateItems.count == 23)
        #expect(panel.candidatePageItems.count == 10)
        #expect(panel.candidatePageCount == 3)
        let tab = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, characters: "\t", charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48))
        #expect(panel.handleCandidateKey(tab))
        #expect(panel.candidatePageIndex == 1)
        #expect(panel.candidatePageItems.map(\.id) == Array(panel.candidateItems[10..<20]).map(\.id))
        #expect(panel.candidateSelectedID == panel.candidatePageItems.first?.id)
        panel.nextCandidatePage()
        #expect(panel.candidatePageItems.count == 3)
        panel.nextCandidatePage()
        #expect(panel.candidatePageIndex == 2)
        panel.previousCandidatePage()
        let expected = panel.candidatePageItems[9].plainText
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                                                windowNumber: 0, context: nil, characters: "0", charactersIgnoringModifiers: "0", isARepeat: false, keyCode: 29))
        #expect(panel.handleCandidateKey(event))
        for _ in 0..<100 {
            if board.string(forType: .string) == expected { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(board.string(forType: .string) == expected)
        #expect(!suppressed.isEmpty)
        let commandEvent = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
                                                windowNumber: 0, context: nil, characters: "3", charactersIgnoringModifiers: "3", isARepeat: false, keyCode: 20))
        #expect(!panel.handleCandidateKey(commandEvent))
    }

    @Test func abbreviatedCandidateLabelsKeepFullTextAndOCRPayload() async throws {
        let original = "第一行内容\n第二行内容\n| 表格 | 单元格 |"
        let text = ClipItem(title: "Synthetic multiline", plainText: original, primaryType: .text,
                            pasteboardTypes: [], contentHash: "summary-text")
        let image = ClipItem(title: "Synthetic OCR", primaryType: .image, pasteboardTypes: [],
                             ocrText: original, contentHash: "summary-ocr")
        #expect(CandidateRowContent.labelText(for: text) == "第一行内容…")
        #expect(CandidateRowContent.labelText(for: image) == "第一行内容…")
        #expect(text.plainText == original)
        #expect(image.ocrText == original)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteItEphemeral-RowSummary-\(UUID())")
        let blob = BlobStore(rootURL: root)
        defer { try? FileManager.default.removeItem(at: root) }
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let writer = PasteController(blobStore: blob, pasteboard: board)
        #expect(await writer.copyToPasteboardAsync(text))
        #expect(board.string(forType: .string) == original)
    }

}
