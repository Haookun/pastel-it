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

    @Test func candidatePlainCopyRecognizesOnClickAndRejectsMissingImage() async throws {
        let name = "PastelIt-Menu-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteItEphemeral-Menu-\(UUID())")
        let settings = AppSettings(defaults: defaults)
        settings.timelinePrimaryAction = .copyOnly
        let store = HistoryStore(ephemeralBlobRoot: root, settings: settings)
        let board = NSPasteboard.withUniqueName()
        defer {
            board.releaseGlobally()
            store.destroyEphemeralFiles()
            defaults.removePersistentDomain(forName: name)
        }
        let original = "Synthetic OCR first line\nsecond line"
        let imageData = Data([1, 2, 3, 4])
        let imagePath = try store.blobStore.store(data: imageData, preferredExtension: "png", id: UUID())
        let image = ClipItem(title: "Synthetic image", primaryType: .image, pasteboardTypes: [],
                             blobRelativePath: imagePath, ocrText: "Stale OCR must not be reused", contentHash: "menu-ocr")
        var configuration = settings.ocrConfiguration
        configuration.enabled = false
        settings.ocrConfiguration = configuration
        let emptyImage = ClipItem(title: "Synthetic empty image", primaryType: .image,
                                  pasteboardTypes: [], contentHash: "menu-empty")
        store.context.insert(image)
        store.context.insert(emptyImage)
        store.refresh()
        let state = AppState(settings: settings, historyStore: store, searchService: SearchService())
        let writer = PasteController(blobStore: store.blobStore, pasteboard: board,
            recognizeImageText: { data, config in
                #expect(data == imageData)
                #expect(config.enabled)
                return original
            })
        var suppressed: [Int] = []
        writer.onPasteboardMutation = { suppressed.append($0) }
        let panel = TimelinePanelController(appState: state, pasteController: writer)
        state.panelController = panel
        panel.activateCandidate(image, action: .copyPlainText)
        for _ in 0..<100 {
            if board.string(forType: .string) == original {
                try await Task.sleep(for: .milliseconds(20))
                break
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(board.string(forType: .string) == original)
        #expect(board.data(forType: .html) == nil)
        #expect(board.data(forType: .png) == nil)
        #expect(suppressed.count == 1)
        let changeCount = board.changeCount
        panel.activateCandidate(emptyImage, action: .copyPlainText)
        try await Task.sleep(for: .milliseconds(50))
        #expect(board.changeCount == changeCount)
        #expect(board.string(forType: .string) == original)
        #expect(panel.candidateMessage != nil)
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

    @Test func candidateRightClickRoutesThroughExplicitEntryPoints() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteItEphemeral-RightClick-\(UUID())")
        let blob = BlobStore(rootURL: root)
        defer { try? FileManager.default.removeItem(at: root) }

        var activated: [UUID] = []
        let coordinator = CandidateTableView.Coordinator(onActivate: { activated.append($0.id) }, blobStore: blob)
        coordinator.onPaste = { _ in }
        coordinator.onPastePlainText = { _ in }
        coordinator.onCopyPlainText = { _ in }

        let table = CandidateNativeTableView()
        table.frame = NSRect(x: 0, y: 0, width: 300, height: 160)
        table.rowHeight = 36
        table.intercellSpacing = .zero
        table.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("candidate")))
        table.dataSource = coordinator
        table.delegate = coordinator
        table.target = coordinator
        table.action = #selector(CandidateTableView.Coordinator.handleClick(_:))
        coordinator.attach(tableView: table)
        defer { coordinator.teardown() }
        let items = (0..<3).map {
            ClipItem(title: "Synthetic \($0)", plainText: "Synthetic \($0)", primaryType: .text,
                     pasteboardTypes: [], contentHash: "rightclick-\($0)")
        }
        coordinator.update(items: items, selectedID: nil, pageIndex: 0, dismissPreviewRequest: nil)

        var presented: [NSMenu] = []
        table.menuPresenter = { menu, _, _ in presented.append(menu) }

        func mouseEvent(_ type: NSEvent.EventType, y: CGFloat, flags: NSEvent.ModifierFlags = []) -> NSEvent {
            NSEvent.mouseEvent(with: type, location: table.convert(NSPoint(x: 10, y: y), to: nil), modifierFlags: flags,
                               timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0,
                               clickCount: 1, pressure: 0)!
        }

        // Right-click on a non-first row pops up exactly one menu, selects
        // that row and never routes through single-click activation.
        table.rightMouseDown(with: mouseEvent(.rightMouseDown, y: table.rowHeight * 1.5))
        #expect(presented.count == 1)
        #expect(table.selectedRow == 1)
        #expect(presented.first?.items.count == 3)
        #expect(presented.first?.items.allSatisfy { ($0.representedObject as? UUID) == items[1].id } == true)
        #expect(activated.isEmpty)

        // Blank area below the rows: no popup, selection untouched.
        table.rightMouseDown(with: mouseEvent(.rightMouseDown, y: table.rowHeight * 3.5))
        #expect(presented.count == 1)
        #expect(table.selectedRow == 1)

        // Ctrl-left-click takes the same menu path without activating.
        table.mouseDown(with: mouseEvent(.leftMouseDown, y: table.rowHeight * 0.5, flags: .control))
        #expect(presented.count == 2)
        #expect(table.selectedRow == 0)
        #expect(activated.isEmpty)

        // The Coordinator-built menu carries the three expected entries.
        let menu = try #require(coordinator.contextMenu(forRow: 1))
        #expect(menu.items.count == 3)
        #expect(menu.items.allSatisfy { $0.isEnabled && !$0.title.isEmpty })
    }

}
