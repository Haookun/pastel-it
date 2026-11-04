import Foundation

struct DiagnosticLogSummary: Sendable {
    let fileCount: Int
    let totalBytes: Int64
}

/// Only fixed diagnostic codes can enter these files; no arbitrary user/error text.
enum DiagnosticEvent: String, Sendable {
    case applicationStarted = "application.started"
    case applicationStopped = "application.stopped"
    case historyOpenFailed = "history.open_failed"
    case historySaveFailed = "history.save_failed"
    case historyMigrationFailed = "history.migration_failed"
    case loginItemUpdateFailed = "login_item.update_failed"
}

/// Dedicated local files, independent of preferences, history, attachments and OS logs.
/// Calls are serialized by DiagnosticLogs on the main actor in the application.
struct DiagnosticLogStore: Sendable {
    let directory: URL
    static let maximumFileBytes = 256 * 1024
    static let retention: TimeInterval = 14 * 24 * 60 * 60
    private let names = ["diagnostic.log", "diagnostic.1.log", "diagnostic.2.log"]

    func snapshot() throws -> DiagnosticLogSummary {
        let files = try existingFiles()
        var bytes: Int64 = 0
        for file in files {
            bytes += Int64(try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
        }
        return DiagnosticLogSummary(fileCount: files.count, totalBytes: bytes)
    }

    /// Deletes only the three owned regular files. Never enumerates/deletes recursively.
    @discardableResult
    func clearPastLogs() throws -> Int {
        let files = try existingFiles()
        for file in files { try FileManager.default.removeItem(at: file) }
        return files.count
    }

    func record(_ event: DiagnosticEvent, at date: Date = Date()) throws {
        try validateDirectory()
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true,
                               attributes: [.posixPermissions: 0o700])
        // Keep both time and size bounds. File rotation preserves the newest diagnostics.
        for file in try existingFiles() {
            let values = try file.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let oldest = [values.creationDate, values.contentModificationDate].compactMap { $0 }.min()
            if let oldest, date.timeIntervalSince(oldest) > Self.retention {
                try fm.removeItem(at: file)
            }
        }
        let line = Data("\(ISO8601DateFormatter().string(from: date)) \(event.rawValue)\n".utf8)
        let current = directory.appendingPathComponent(names[0])
        try validateOwnedFiles()
        let size = (try? current.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        if size + line.count > Self.maximumFileBytes {
            let oldest = directory.appendingPathComponent(names[2])
            if fm.fileExists(atPath: oldest.path) { try fm.removeItem(at: oldest) }
            for index in stride(from: 1, through: 0, by: -1) {
                let source = directory.appendingPathComponent(names[index])
                if fm.fileExists(atPath: source.path) {
                    try fm.moveItem(at: source, to: directory.appendingPathComponent(names[index + 1]))
                }
            }
        }
        if !fm.fileExists(atPath: current.path) {
            guard fm.createFile(atPath: current.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forWritingTo: current)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }

    private func existingFiles() throws -> [URL] {
        try validateDirectory()
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        try validateOwnedFiles()
        return names.map { directory.appendingPathComponent($0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Refuse redirects to preferences/history through symlinks, including ancestor links.
    private func validateDirectory() throws {
        var cursor = directory.path
        while cursor != "/" && !cursor.isEmpty {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: cursor),
               let type = attributes[.type] as? FileAttributeType,
               type != .typeDirectory {
                // Foundation canonicalizes macOS temporary URLs through /var.
                // Only OS-owned root aliases are allowed; app/log links are refused.
                let aliases = ["/var": "private/var", "/tmp": "private/tmp"]
                let target = try? FileManager.default.destinationOfSymbolicLink(atPath: cursor)
                guard type == .typeSymbolicLink, let expected = aliases[cursor], target == expected else {
                    throw CocoaError(.fileWriteInvalidFileName)
                }
            }
            cursor = (cursor as NSString).deletingLastPathComponent
        }
    }

    private func validateOwnedFiles() throws {
        for name in names {
            let url = directory.appendingPathComponent(name)
            // attributesOfItem inspects the link itself; broken links are refused too.
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let type = attributes[.type] as? FileAttributeType {
                guard type == .typeRegular, (attributes[.referenceCount] as? Int ?? 1) == 1 else {
                    throw CocoaError(.fileWriteInvalidFileName)
                }
            }
        }
    }
}

@MainActor
final class DiagnosticLogs {
    static let shared = DiagnosticLogs()
    let store: DiagnosticLogStore

    private init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isolated = arguments.contains("--validation-session") || arguments.contains("--ui-review")
            || Bundle.main.bundleURL.pathExtension != "app"
        let root = isolated
            ? FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent("PastelIt-Diagnostics-\(UUID())")
            : FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/PastelItPublic")
        store = DiagnosticLogStore(directory: root)
    }

    func record(_ event: DiagnosticEvent) {
        // A logging failure must not interrupt clipboard capture/paste or emit user data.
        try? store.record(event)
    }
}
