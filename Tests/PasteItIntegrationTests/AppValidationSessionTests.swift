import Foundation
import Testing
@testable import PasteIt

@MainActor
@Suite("Isolated app validation", .serialized)
struct AppValidationSessionTests {
    @Test func usesSyntheticHistoryAndIndependentPreferences() throws {
        let first = AppValidationSession()
        let second = AppValidationSession()
        defer { first.tearDown(); second.tearDown() }
        #expect(first.defaultsDomain != second.defaultsDomain)
        #expect(first.historyStore.blobStore.rootURL != second.historyStore.blobStore.rootURL)
        #expect(first.historyStore.blobStore.rootURL.lastPathComponent.hasPrefix("PasteItEphemeral-Validation-"))
        #expect(!first.settings.launchAtLogin)
        #expect(!first.settings.analyticsEnabled)
        #expect(!first.settings.agentAPIEnabled)
        #expect(first.settings.hasCompletedOnboarding)
        #expect(first.historyStore.clips.count == 48)
        #expect(first.historyStore.clips.allSatisfy { $0.plainText.hasPrefix("Synthetic note ") })
        first.settings.quickPasteEnabled = true
        #expect(!second.settings.quickPasteEnabled)
        let root = first.historyStore.blobStore.rootURL
        #expect(FileManager.default.fileExists(atPath: root.path))
        first.tearDown()
        #expect(!FileManager.default.fileExists(atPath: root.path))
        #expect(first.defaults.persistentDomain(forName: first.defaultsDomain)?.isEmpty != false)
        #expect(second.historyStore.clips.count == 48)
    }
}
