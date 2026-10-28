import Foundation
import PasteItCore

/// Safely resolves resources without invoking SwiftPM's fatal Bundle.module accessor.
enum LocalizationResources {
    enum Source: Equatable { case packaged, repaired, englishFallback }
    struct Resolution {
        let bundle: Bundle
        let source: Source
    }

    static var cacheRoot: URL {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--validation-session") || arguments.contains("--ui-review") {
            return FileManager.default.temporaryDirectory.appendingPathComponent("PastelIt-LanguageValidation-\(ProcessInfo.processInfo.processIdentifier)")
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PasteIt/LanguagePacks", isDirectory: true)
    }

    static func resolve(mainBundle: Bundle = .main, cache: URL? = nil) -> Resolution {
        var candidates = [mainBundle.bundleURL.appendingPathComponent("Contents/Resources/PasteIt_PasteIt.bundle")]
        if let url = mainBundle.url(forResource: "PasteIt_PasteIt", withExtension: "bundle") { candidates.append(url) }
        // Bare SwiftPM tools/tests keep resources beside their executable. A packaged
        // application never searches paths on the build machine or another installed app.
        if mainBundle.bundleURL.pathExtension != "app", let executable = mainBundle.executableURL {
            candidates.append(executable.deletingLastPathComponent().appendingPathComponent("PasteIt_PasteIt.bundle"))
            candidates.append(mainBundle.bundleURL.deletingLastPathComponent().appendingPathComponent("PasteIt_PasteIt.bundle"))
        }
        for url in candidates {
            if let bundle = validatedBundle(at: url) { return Resolution(bundle: bundle, source: .packaged) }
        }
        let repaired = (cache ?? cacheRoot).appendingPathComponent(LanguagePackManifest.sha256 + ".bundle")
        if let bundle = validatedBundle(at: repaired) { return Resolution(bundle: bundle, source: .repaired) }
        // Every production string already supplies a built-in English default to L10n.tr.
        return Resolution(bundle: mainBundle, source: .englishFallback)
    }

    static func validatedBundle(at url: URL) -> Bundle? {
        guard let bundle = Bundle(url: url) else { return nil }
        for (locale, digest) in LanguagePackManifest.translationDigests {
            guard let file = bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: locale),
                  let data = try? Data(contentsOf: file, options: [.mappedIfSafe]),
                  data.count <= LanguagePack.maximumBytes,
                  let translations = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
                  LanguagePack.digest(translations) == digest else { return nil }
        }
        return bundle
    }

    static func install(_ data: Data, cache: URL? = nil) throws -> Bundle {
        let pack = try LanguagePack.validated(data)
        let root = cache ?? cacheRoot
        try refuseRedirects(root)
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let destination = root.appendingPathComponent(LanguagePackManifest.sha256 + ".bundle")
        if let bundle = validatedBundle(at: destination) { return bundle }
        try refuseRedirects(destination)
        let stage = root.appendingPathComponent("staging-\(UUID()).bundle")
        let old = root.appendingPathComponent("replaced-\(UUID()).bundle")
        defer { try? fm.removeItem(at: stage) }
        let resources = stage.appendingPathComponent("Contents/Resources")
        try fm.createDirectory(at: resources, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let info: [String: Any] = ["CFBundleIdentifier": "app.paste-it.languages", "CFBundleDevelopmentRegion": "en",
                                  "CFBundlePackageType": "BNDL", "CFBundleLocalizations": Array(pack.localizations.keys).sorted()]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: stage.appendingPathComponent("Contents/Info.plist"), options: .atomic)
        for (locale, translations) in pack.localizations {
            let folder = resources.appendingPathComponent(locale + ".lproj")
            try fm.createDirectory(at: folder, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            let file = folder.appendingPathComponent("Localizable.strings")
            try PropertyListSerialization.data(fromPropertyList: translations, format: .binary, options: 0)
                .write(to: file, options: .atomic)
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        }
        guard validatedBundle(at: stage) != nil else { throw LanguagePack.ValidationError.invalidTranslations }
        let replacing = fm.fileExists(atPath: destination.path)
        if replacing { try fm.moveItem(at: destination, to: old) }
        do {
            try fm.moveItem(at: stage, to: destination)
        } catch {
            if replacing { try? fm.moveItem(at: old, to: destination) }
            throw error
        }
        if replacing { try? fm.removeItem(at: old) }
        guard let bundle = validatedBundle(at: destination) else { throw LanguagePack.ValidationError.invalidTranslations }
        return bundle
    }

    private static func refuseRedirects(_ url: URL) throws {
        var cursor = url.path
        while cursor != "/" && !cursor.isEmpty {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: cursor),
               let type = attributes[.type] as? FileAttributeType, type != .typeDirectory {
                let aliases = ["/var": "private/var", "/tmp": "private/tmp"]
                let target = try? FileManager.default.destinationOfSymbolicLink(atPath: cursor)
                guard type == .typeSymbolicLink, let expected = aliases[cursor], target == expected else {
                    throw CocoaError(.fileWriteInvalidFileName)
                }
            }
            cursor = (cursor as NSString).deletingLastPathComponent
        }
    }
}
