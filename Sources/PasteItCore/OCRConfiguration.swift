import Foundation

public struct OCRConfiguration: Codable, Equatable, Sendable {
    public enum Accuracy: String, Codable, CaseIterable, Sendable {
        case accurate, fast
    }

    public var enabled = true
    /// An empty list lets Vision select its language model automatically.
    public var languages: [String] = []
    public var detectsTables = true
    public var accuracy: Accuracy = .accurate
    public var languageCorrection = false
    public var minimumTextHeight: Double = 0

    public init() {}

    public var normalized: Self {
        var value = self
        value.languages = Array(Set(languages.filter { !$0.isEmpty })).sorted()
        value.minimumTextHeight = minimumTextHeight.isFinite ? min(0.1, max(0, minimumTextHeight)) : 0
        return value
    }
}

public struct QuickPasteScope: Codable, Equatable, Sendable {
    public var text = true
    public var images = true
    public var fileNames = true
    public init() {}
    public var isEmpty: Bool { !text && !images && !fileNames }
}
