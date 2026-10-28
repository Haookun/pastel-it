import Foundation
import PasteItCore

protocol LanguagePackDownloading: Sendable {
    func download(from url: URL) async throws -> Data
}

enum LanguagePackDownloadError: Error {
    case signInOrFileUnavailable, serverUnavailable, invalidURL, tooLarge
}

enum LanguagePackEndpoint {
    static let download = URL(string: "https://raw.githubusercontent.com/Haookun/pastel-it/main/" + LanguagePackManifest.relativePath)!
    static let browser = URL(string: "https://github.com/Haookun/pastel-it/blob/main/" + LanguagePackManifest.relativePath + "?raw=true")!

    static func isAllowed(_ url: URL) -> Bool {
        url.scheme == "https" && url.user == nil && url.password == nil && (url.port == nil || url.port == 443)
            && ["github.com", "raw.githubusercontent.com"].contains(url.host?.lowercased() ?? "")
    }
}

private final class LanguagePackRedirectPolicy: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(request.url.flatMap { LanguagePackEndpoint.isAllowed($0) ? request : nil })
    }
}

struct LanguagePackDownloader: LanguagePackDownloading {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 60
        session = URLSession(configuration: configuration, delegate: LanguagePackRedirectPolicy(), delegateQueue: nil)
    }

    func download(from url: URL) async throws -> Data {
        guard LanguagePackEndpoint.isAllowed(url) else { throw LanguagePackDownloadError.invalidURL }
        let (bytes, response) = try await session.bytes(for: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        defer { bytes.task.cancel() }
        guard let http = response as? HTTPURLResponse, let finalURL = http.url,
              LanguagePackEndpoint.isAllowed(finalURL) else { throw LanguagePackDownloadError.invalidURL }
        if [401, 403, 404].contains(http.statusCode) { throw LanguagePackDownloadError.signInOrFileUnavailable }
        guard http.statusCode == 200 else { throw LanguagePackDownloadError.serverUnavailable }
        if (http.mimeType ?? "").contains("html") { throw LanguagePackDownloadError.signInOrFileUnavailable }
        guard http.expectedContentLength <= Int64(LanguagePack.maximumBytes) else { throw LanguagePackDownloadError.tooLarge }
        var data = Data()
        for try await byte in bytes {
            guard data.count < LanguagePack.maximumBytes else { throw LanguagePackDownloadError.tooLarge }
            data.append(byte)
        }
        return data
    }
}
