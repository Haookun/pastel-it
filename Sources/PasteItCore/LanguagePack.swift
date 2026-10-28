import CryptoKit
import Foundation

/// Data only: no scripts, archives, executable code or arbitrary installation paths.
public struct LanguagePack: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let applicationIdentifier: String
    public let appVersion: String
    public let appBuild: String
    public let localizations: [String: [String: String]]

    public static let maximumBytes = 2 * 1024 * 1024

    public enum ValidationError: Error {
        case invalidSize, integrityMismatch, incompatibleVersion, invalidTranslations
    }

    public static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public static func digest(_ translations: [String: String]) -> String {
        var data = Data()
        for key in translations.keys.sorted() {
            guard let value = translations[key] else { continue }
            data.append(Data("\(key.utf8.count):\(key)\(value.utf8.count):\(value)".utf8))
        }
        return sha256(data)
    }

    public static func validated(_ data: Data) throws -> Self {
        guard !data.isEmpty, data.count <= maximumBytes else { throw ValidationError.invalidSize }
        guard sha256(data) == LanguagePackManifest.sha256 else { throw ValidationError.integrityMismatch }
        let pack = try JSONDecoder().decode(Self.self, from: data)
        guard pack.schemaVersion == 1,
              pack.applicationIdentifier == "app.paste-it.mac",
              pack.appVersion == LanguagePackManifest.appVersion,
              pack.appBuild == LanguagePackManifest.appBuild else { throw ValidationError.incompatibleVersion }
        guard Set(pack.localizations.keys) == Set(LanguagePackManifest.translationDigests.keys),
              let english = pack.localizations["en"], !english.isEmpty else { throw ValidationError.invalidTranslations }
        for (locale, translations) in pack.localizations {
            guard Set(translations.keys) == Set(english.keys),
                  digest(translations) == LanguagePackManifest.translationDigests[locale] else {
                throw ValidationError.invalidTranslations
            }
        }
        return pack
    }
}
