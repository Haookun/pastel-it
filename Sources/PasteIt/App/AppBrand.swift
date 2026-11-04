import Foundation

enum AppBrand {
    static let displayName = "Pastel it！"
    static let repositoryURL = URL(string: "https://github.com/Haookun/pastel-it")!
    // This independent derivative must never install upstream updates.
    static let updatesEnabled = false
}

/// Archived features have no runtime entry point in this personal build.
enum AppFeatures {
    static let pasteStackEnabled = false
    static let mcpEnabled = false
}
