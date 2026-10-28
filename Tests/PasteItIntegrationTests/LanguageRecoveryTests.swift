import AppKit
import Foundation
import PasteItCore
import Testing
@testable import PasteIt

private struct RecoveryTestDownloader: LanguagePackDownloading {
    var data: Data = Data()
    var requiresLogin = false
    func download(from url: URL) async throws -> Data {
        if requiresLogin { throw LanguagePackDownloadError.signInOrFileUnavailable }
        return data
    }
}

@MainActor
@Suite("Missing language resource recovery", .serialized)
struct LanguageRecoveryTests {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
    private func pack() throws -> Data { try Data(contentsOf: root.appendingPathComponent(LanguagePackManifest.relativePath)) }
    private func temporaryRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PastelIt-LanguageTests-\(UUID())")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private func emptyApp(at root: URL) throws -> Bundle {
        let app = root.appendingPathComponent("Empty.app")
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents"), withIntermediateDirectories: true)
        let info = ["CFBundleIdentifier": "app.paste-it.synthetic", "CFBundleName": "Synthetic"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: app.appendingPathComponent("Contents/Info.plist"))
        return try #require(Bundle(url: app))
    }

    @Test func absentResourcesUseEnglishWithoutTheFatalModuleAccessor() throws {
        let temp = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: temp) }
        let result = LocalizationResources.resolve(mainBundle: try emptyApp(at: temp), cache: temp.appendingPathComponent("LanguagePacks"))
        #expect(result.source == .englishFallback)
        #expect(result.bundle.localizedString(forKey: "ocr.correction", value: "Language correction", table: nil) == "Language correction")
    }

    @Test func validPackInstallsTranslationsWithoutChangingPreferencesOrHistory() throws {
        let temp = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: temp) }
        let sentinels = ["preferences.plist", "history.store", "attachment.png"]
        for file in sentinels { try Data("keep-me".utf8).write(to: temp.appendingPathComponent(file)) }
        let cache = temp.appendingPathComponent("LanguagePacks")
        let bundle = try LocalizationResources.install(pack(), cache: cache)
        #expect(LocalizationResources.validatedBundle(at: bundle.bundleURL) != nil)
        let chinese = try #require(bundle.path(forResource: "zh-Hans", ofType: "lproj").flatMap(Bundle.init(path:)))
        #expect(chinese.localizedString(forKey: "ocr.correction", value: "missing", table: nil) == "语言纠错")
        #expect(LocalizationResources.resolve(mainBundle: try emptyApp(at: temp), cache: cache).source == .repaired)
        for file in sentinels { #expect(try String(contentsOf: temp.appendingPathComponent(file), encoding: .utf8) == "keep-me") }
        #expect(try LocalizationResources.install(pack(), cache: cache).bundleURL == bundle.bundleURL)
    }

    @Test func tamperedAndWrongVersionPacksCannotCreateOrReplaceFiles() throws {
        let temp = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: temp) }
        let cache = temp.appendingPathComponent("LanguagePacks")
        var altered = try pack(); altered[altered.startIndex] = 32
        #expect(throws: (any Error).self) { try LocalizationResources.install(altered, cache: cache) }
        var json = try #require(JSONSerialization.jsonObject(with: pack()) as? [String: Any])
        json["appBuild"] = "wrong-version"
        let mismatched = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: (any Error).self) { try LocalizationResources.install(mismatched, cache: cache) }
        #expect(!FileManager.default.fileExists(atPath: cache.path))
        #expect(throws: (any Error).self) { try LanguagePack.validated(Data(repeating: 0, count: LanguagePack.maximumBytes + 1)) }
    }

    @Test func missingOrCorruptCachedLanguageFallsBackAndCanBeRepaired() throws {
        let temp = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: temp) }
        let cache = temp.appendingPathComponent("LanguagePacks")
        let bundle = try LocalizationResources.install(pack(), cache: cache)
        let japanese = try #require(bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "ja"))
        try Data("corrupt".utf8).write(to: japanese)
        #expect(LocalizationResources.resolve(mainBundle: try emptyApp(at: temp), cache: cache).source == .englishFallback)
        #expect(LocalizationResources.validatedBundle(at: try LocalizationResources.install(pack(), cache: cache).bundleURL) != nil)
    }

    @Test func installationRefusesSymlinkedCacheAndPreservesTheTarget() throws {
        let temp = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: temp) }
        let target = temp.appendingPathComponent("settings")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        let sentinel = target.appendingPathComponent("preferences.plist")
        try Data("keep-me".utf8).write(to: sentinel)
        let link = temp.appendingPathComponent("LanguagePacks")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        #expect(throws: (any Error).self) { try LocalizationResources.install(pack(), cache: link) }
        #expect(try String(contentsOf: sentinel, encoding: .utf8) == "keep-me")
    }

    @Test func privateRepositoryFailureKeepsEnglishAndOffersBrowserImport() async throws {
        let oldBundle = L10n.bundle; defer { L10n.bundle = oldBundle }
        let temp = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: temp) }
        let cache = temp.appendingPathComponent("LanguagePacks")
        let controller = LanguageRepairController(cache: cache, downloader: RecoveryTestDownloader(requiresLogin: true))
        controller.configure(LocalizationResources.resolve(mainBundle: try emptyApp(at: temp), cache: cache))
        await controller.downloadAndInstall()
        #expect(controller.needsRepair)
        #expect(controller.requiresBrowserLogin)
        #expect(!controller.isBusy)
        #expect(controller.message != nil)
        #expect(!FileManager.default.fileExists(atPath: cache.path))
    }

    @Test func successfulDownloadRepairsResourcesWithoutCredentialsOrReinstall() async throws {
        let oldBundle = L10n.bundle; defer { L10n.bundle = oldBundle }
        let temp = try temporaryRoot(); defer { try? FileManager.default.removeItem(at: temp) }
        let controller = LanguageRepairController(cache: temp.appendingPathComponent("LanguagePacks"), downloader: RecoveryTestDownloader(data: try pack()))
        await controller.downloadAndInstall()
        #expect(!controller.needsRepair)
        #expect(!controller.isBusy)
        #expect(!controller.requiresBrowserLogin)
        #expect(LocalizationResources.validatedBundle(at: L10n.bundle.bundleURL) != nil)
    }

    @Test func rejectsUnexpectedHostsCredentialsAndInsecureDownloadAddresses() throws {
        for url in ["http://github.com/pack", "https://github.com.evil.invalid/pack", "https://user:secret@github.com/pack", "https://github.com:8443/pack", "file:///tmp/pack"] {
            #expect(!LanguagePackEndpoint.isAllowed(try #require(URL(string: url))))
        }
        #expect(LanguagePackEndpoint.isAllowed(LanguagePackEndpoint.download))
        #expect(LanguagePackEndpoint.isAllowed(LanguagePackEndpoint.browser))
    }
}
