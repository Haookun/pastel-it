import Foundation

/// Presentation-only label. The stored clip, OCR text and pasteboard payload
/// remain complete; the native text field handles additional width truncation.
public enum CandidateRowSummary {
    public static func firstLine(_ text: String, limit: Int = 512) -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let separator = text.firstIndex(where: \.isNewline)
        let line = String(text[..<(separator ?? text.endIndex)]).trimmingCharacters(in: .whitespaces)
        let prefix = line.prefix(max(0, limit))
        let hasMore = separator != nil || prefix.endIndex < line.endIndex
        return String(prefix) + (hasMore && !prefix.hasSuffix("…") ? "…" : "")
    }
}
