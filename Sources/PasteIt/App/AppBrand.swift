import Foundation

enum AppBrand {
    static let displayName = "Pastel it！"
    static let repositoryURL = URL(string: "https://github.com/Haookun/pastel-it")!
    // A private derivative must never install updates signed for the upstream app.
    static let updatesEnabled = false
}

/// Archived features have no runtime entry point in this personal build.
enum AppFeatures {
    static let pasteStackEnabled = false
    static let mcpEnabled = false
}
