import AppKit
import Foundation
import Testing
import PasteItCore
@testable import PasteIt

@MainActor
@Suite("OCR preferences and quick clipboard conversion", .serialized)
struct OCRPreferencesAndQuickPasteTests {
    private func manager(_ defaults: UserDefaults) -> HotkeyManager {
        HotkeyManager(defaults: defaults, showTimeline: {}, togglePasteStack: {},
                      pastePlain: { false }, editSelected: { false })
    }

    @Test func settingsSurviveRestartAndRemainInTheirOwnDomain() throws {
        let name = "PasteIt-OCR-Preferences-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.ocrConfiguration == OCRConfiguration())
        #expect(!settings.quickPasteEnabled)
        var configuration = OCRConfiguration()
        configuration.enabled = false
        configuration.languages = ["ja-JP", "en-US"]
        configuration.detectsTables = false
        configuration.accuracy = .fast
        configuration.languageCorrection = true
        configuration.minimumTextHeight = 0.025
        settings.ocrConfiguration = configuration
        var scope = QuickPasteScope()
        scope.images = false
        scope.fileNames = false
        settings.quickPasteScope = scope
        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.ocrConfiguration == configuration.normalized)
        #expect(reloaded.quickPasteScope == scope)
        #expect(!reloaded.quickPasteEnabled)
    }

    @Test func quickPasteConflictsDoNotReplaceExistingShortcuts() throws {
        let name = "PasteIt-Quick-Shortcuts-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let keys = manager(defaults)
        #expect(!keys.setQuickPasteEnabled(true))
        #expect(keys.shortcuts == .defaults)
        #expect(keys.errorMessage != nil)
        #expect(!defaults.bool(forKey: "quickPasteEnabled"))
        #expect(keys.set(ShortcutBinding(keyCode: 9, modifiers: [.command, .option], key: "V"), for: .timeline))
        #expect(keys.setQuickPasteEnabled(true))
        #expect(keys.shortcuts.quickPaste == ShortcutAction.quickPaste.defaultBinding)
        #expect(defaults.bool(forKey: "quickPasteEnabled"))
        #expect(manager(defaults).shortcuts == keys.shortcuts)
        #expect(keys.clear(.quickPaste))
        #expect(!defaults.bool(forKey: "quickPasteEnabled"))
        #expect(keys.shortcuts.timeline?.modifiers == [.command, .option])
    }

    @Test func convertsOnlyEnabledTypesAndPreservesClipboard() async throws {
        let board = NSPasteboard.withUniqueName()
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteIt-Quick-\(UUID())")
        defer { board.releaseGlobally(); try? FileManager.default.removeItem(at: root) }
        let paste = PasteController(blobStore: BlobStore(rootURL: root), pasteboard: board)
        let rich = NSPasteboardItem()
        rich.setString("<b>Synthetic 4821</b>", forType: .html)
        board.writeObjects([rich])
        let originalCount = board.changeCount
        #expect(await paste.quickPasteText(scope: .init(), configuration: .init(), ignoredTypes: []) == "Synthetic 4821")
        #expect(board.changeCount == originalCount)
        #expect(board.string(forType: .html) == "<b>Synthetic 4821</b>")
        var scope = QuickPasteScope()
        scope.text = false
        #expect(await paste.quickPasteText(scope: scope, configuration: .init(), ignoredTypes: []) == nil)
        #expect(await paste.quickPasteText(scope: .init(), configuration: .init(), ignoredTypes: [NSPasteboard.PasteboardType.html.rawValue]) == nil)

        board.clearContents()
        board.writeObjects([root.appendingPathComponent("合成文档.txt") as NSURL,
                            root.appendingPathComponent("Sample.pdf") as NSURL])
        #expect(await paste.quickPasteText(scope: .init(), configuration: .init(), ignoredTypes: []) == "合成文档.txt\nSample.pdf")
        scope.fileNames = false
        scope.text = true
        #expect(await paste.quickPasteText(scope: scope, configuration: .init(), ignoredTypes: []) == nil)
    }

    @Test func mouseWheelMovesNativeHorizontalScrollAndClampsAtEdges() {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 240))
        scroll.documentView = NSView(frame: NSRect(x: 0, y: 0, width: 3000, height: 232))
        scroll.tile()
        TimelineWheelScrolling.WheelView.scroll(delta: 120, in: scroll)
        #expect(scroll.contentView.bounds.origin.x == 120)
        TimelineWheelScrolling.WheelView.scroll(delta: 10000, in: scroll)
        #expect(scroll.contentView.bounds.maxX == 3000)
        TimelineWheelScrolling.WheelView.scroll(delta: -10000, in: scroll)
        #expect(scroll.contentView.bounds.origin.x == 0)
    }
}
