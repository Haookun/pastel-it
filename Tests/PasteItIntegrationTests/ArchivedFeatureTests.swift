import AppKit
import Foundation
import Testing
import PasteItCore
@testable import PasteIt

@MainActor
@Suite("Archived feature isolation", .serialized)
struct ArchivedFeatureTests {
    @Test func savedMCPEnabledCannotRestoreTheListener() throws {
        let name = "PastelIt-Archived-Tests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(true, forKey: "agentAPIEnabled")
        let settings = AppSettings(defaults: defaults)
        #expect(!AppFeatures.mcpEnabled)
        #expect(!settings.agentAPIEnabled)
        #expect(!defaults.bool(forKey: "agentAPIEnabled"))
        settings.agentAPIEnabled = true
        #expect(!settings.agentAPIEnabled)
        AgentAPIServer.shared.start(forceRestart: true)
        #expect(!AgentAPIServer.shared.isRunning)
    }

    @Test func archivedStackCannotCollectOrReclaimTheHistoryShortcut() throws {
        let name = "PastelIt-Archived-Tests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PasteItEphemeral-Archived-\(UUID())")
        let board = NSPasteboard.withUniqueName()
        defer {
            board.releaseGlobally()
            defaults.removePersistentDomain(forName: name)
            try? FileManager.default.removeItem(at: root)
        }
        let settings = AppSettings(defaults: defaults)
        let paste = PasteController(blobStore: BlobStore(rootURL: root), pasteboard: board)
        let stack = PasteStackController(pasteController: paste, settings: settings)
        stack.open()
        #expect(!AppFeatures.pasteStackEnabled)
        #expect(!stack.isCollecting)
        #expect(stack.items.isEmpty)
        #expect(ShortcutAction.allCases == [.timeline, .quickPaste])
        #expect(ShortcutConfiguration.defaults.timeline?.display == "⇧⌘C")
        #expect(ShortcutConfiguration.defaults.quickPaste?.display == "⇧⌘V")
        #expect(!OnboardingPageID.pages(for: .install).contains(.stack))
        #expect(!OnboardingPageID.pages(for: .update).contains(.stack))
    }
}
