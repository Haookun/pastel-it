import AppKit
import Combine
import Foundation
import PasteItCore
import UniformTypeIdentifiers

@MainActor
final class LanguageRepairController: ObservableObject {
    static let shared = LanguageRepairController()

    @Published private(set) var needsRepair = false
    @Published private(set) var isBusy = false
    @Published private(set) var message: String?
    @Published private(set) var requiresBrowserLogin = false

    var revealSettings: (() -> Void)?
    private let cache: URL
    private let downloader: any LanguagePackDownloading

    init(cache: URL = LocalizationResources.cacheRoot, downloader: any LanguagePackDownloading = LanguagePackDownloader()) {
        self.cache = cache
        self.downloader = downloader
    }

    func configure(_ resolution: LocalizationResources.Resolution) {
        L10n.bundle = resolution.bundle
        needsRepair = resolution.source == .englishFallback
    }

    func revealRepairSettings() { revealSettings?() }

    func downloadAndInstall() async {
        guard !isBusy else { return }
        isBusy = true
        message = L10n.tr("languageRepair.downloading", default: "Downloading the language resources for this version…")
        defer { isBusy = false }
        do {
            let data = try await downloader.download(from: LanguagePackEndpoint.download)
            try install(data)
        } catch LanguagePackDownloadError.signInOrFileUnavailable {
            requiresBrowserLogin = true
            message = L10n.tr("languageRepair.privateHelp", default: "This repository is private or the file is unavailable. Sign in to GitHub in your browser, download this version’s language pack, then install the downloaded file. English remains available.")
        } catch is LanguagePack.ValidationError {
            message = L10n.tr("languageRepair.invalid", default: "The language pack is damaged or does not match this app version. Nothing was installed. Download the matching pack and try again.")
        } catch {
            message = L10n.tr("languageRepair.failed", default: "The language resources could not be repaired. Check your connection or install a downloaded pack. Your settings and history are unchanged.")
        }
    }

    func openGitHubDownload() {
        NSWorkspace.shared.open(LanguagePackEndpoint.browser)
    }

    func chooseAndInstall() {
        guard !isBusy else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = L10n.tr("languageRepair.chooseFile", default: "Choose the language pack downloaded from this app’s GitHub repository.")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true,
                  let size = values.fileSize, size > 0, size <= LanguagePack.maximumBytes else {
                throw LanguagePack.ValidationError.invalidSize
            }
            try install(Data(contentsOf: url, options: [.mappedIfSafe]))
        } catch {
            message = L10n.tr("languageRepair.invalid", default: "The language pack is damaged or does not match this app version. Nothing was installed. Download the matching pack and try again.")
        }
    }

    func install(_ data: Data) throws {
        let bundle = try LocalizationResources.install(data, cache: cache)
        L10n.bundle = bundle
        needsRepair = false
        requiresBrowserLogin = false
        message = L10n.tr("languageRepair.installed", default: "Language resources installed. Reopen the app for all interface text to refresh. Your settings and history are unchanged.")
    }
}
