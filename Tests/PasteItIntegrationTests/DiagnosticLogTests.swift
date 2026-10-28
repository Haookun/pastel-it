import Foundation
import Testing
@testable import PasteIt

@Suite("Local diagnostics")
struct DiagnosticLogTests {
    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("PastelIt-LogTests-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    @Test func deletionPreservesPreferencesHistoryAttachmentsAndUnrelatedFiles() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let logs = root.appendingPathComponent("Logs")
        let store = DiagnosticLogStore(directory: logs)
        try store.record(.historySaveFailed)
        let sentinels = [root.appendingPathComponent("settings.plist"), root.appendingPathComponent("history.store"),
                         root.appendingPathComponent("attachment.png"), logs.appendingPathComponent("configuration.json")]
        for file in sentinels { try Data("preserve-this".utf8).write(to: file) }
        #expect(try store.snapshot().fileCount == 1)
        #expect(try store.clearPastLogs() == 1)
        #expect(try store.snapshot().totalBytes == 0)
        #expect(try store.clearPastLogs() == 0)
        for file in sentinels { #expect(try String(contentsOf: file, encoding: .utf8) == "preserve-this") }
        try store.record(.historySaveFailed)
        #expect(try store.snapshot().fileCount == 1)
    }

    @Test func diagnosticFilesHaveBoundedSizeAndPrivatePermissions() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = DiagnosticLogStore(directory: root.appendingPathComponent("Logs"))
        try store.record(.historyOpenFailed)
        let current = store.directory.appendingPathComponent("diagnostic.log")
        for _ in 0..<5 {
            try Data(repeating: 65, count: DiagnosticLogStore.maximumFileBytes).write(to: current)
            try store.record(.historySaveFailed)
        }
        let summary = try store.snapshot()
        #expect(summary.fileCount == 3)
        #expect(summary.totalBytes <= 3 * Int64(DiagnosticLogStore.maximumFileBytes))
        let attributes = try FileManager.default.attributesOfItem(atPath: current.path)
        #expect((attributes[.posixPermissions] as? Int ?? 0) & 0o777 == 0o600)
        let contents = try String(contentsOf: current, encoding: .utf8)
        #expect(contents.hasSuffix(" history.save_failed\n"))
        #expect(!contents.contains(NSUserName()))
    }

    @Test func oldLogsExpireAndMissingDirectoryIsSafe() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = DiagnosticLogStore(directory: root.appendingPathComponent("Logs"))
        #expect(try store.clearPastLogs() == 0)
        #expect(try store.snapshot().fileCount == 0)
        try store.record(.historyOpenFailed)
        let current = store.directory.appendingPathComponent("diagnostic.log")
        try FileManager.default.setAttributes([.modificationDate: Date().addingTimeInterval(-15 * 86400)], ofItemAtPath: current.path)
        try store.record(.historySaveFailed)
        let contents = try String(contentsOf: current, encoding: .utf8)
        #expect(!contents.contains("history.open_failed"))
        #expect(contents.contains("history.save_failed"))
    }

    @Test func refusesLogFileAndDirectorySymlinksWithoutTouchingTheirTargets() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let config = root.appendingPathComponent("settings.plist")
        try Data("configuration".utf8).write(to: config)
        let store = DiagnosticLogStore(directory: root.appendingPathComponent("Logs"))
        try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: store.directory.appendingPathComponent("diagnostic.log"), withDestinationURL: config)
        #expect(throws: (any Error).self) { try store.clearPastLogs() }
        #expect(throws: (any Error).self) { try store.record(.historySaveFailed) }
        let linked = root.appendingPathComponent("LinkedLogs")
        try FileManager.default.createSymbolicLink(at: linked, withDestinationURL: store.directory)
        #expect(throws: (any Error).self) { try DiagnosticLogStore(directory: linked).clearPastLogs() }
        #expect(try String(contentsOf: config, encoding: .utf8) == "configuration")
    }

    @Test func refusesDirectoriesAndHardLinksNamedLikeLogFiles() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = DiagnosticLogStore(directory: root.appendingPathComponent("Logs"))
        let fakeLog = store.directory.appendingPathComponent("diagnostic.log")
        try FileManager.default.createDirectory(at: fakeLog, withIntermediateDirectories: true)
        #expect(throws: (any Error).self) { try store.clearPastLogs() }
        try FileManager.default.removeItem(at: fakeLog)
        let config = root.appendingPathComponent("settings.plist")
        try Data("configuration".utf8).write(to: config)
        try FileManager.default.linkItem(at: config, to: fakeLog)
        #expect(throws: (any Error).self) { try store.clearPastLogs() }
        #expect(try String(contentsOf: config, encoding: .utf8) == "configuration")
    }
}
