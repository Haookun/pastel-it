import Foundation
import Testing
@testable import PasteIt

@MainActor
struct PrivateBrandTests {
    @Test func derivativeDoesNotStartOrEnableTheUpstreamUpdater() {
        #expect(AppBrand.displayName == "Pastel it！")
        #expect(AppBrand.repositoryURL.absoluteString == "https://github.com/Haookun/pastel-it")
        #expect(!AppBrand.updatesEnabled)
        let checker = UpdateChecker.shared
        #expect(!checker.canCheckForUpdates)
        checker.automaticallyChecksForUpdates = true
        checker.automaticallyDownloadsUpdates = true
        #expect(!checker.automaticallyChecksForUpdates)
        #expect(!checker.automaticallyDownloadsUpdates)
    }

    @Test func independentBundleUsesNewIdentityAndRemovesUpstreamFeed() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("Info.plist"))
        let info = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        #expect(info["CFBundleDisplayName"] as? String == AppBrand.displayName)
        #expect(info["CFBundleIdentifier"] as? String == "io.github.haookun.pastel-it")
        #expect(info["SUFeedURL"] == nil)
        #expect(info["SUPublicEDKey"] == nil)
        #expect(info["SUEnableAutomaticChecks"] as? Bool == false)
    }
}
