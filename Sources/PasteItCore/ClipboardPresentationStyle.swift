import Foundation

public enum ClipboardPresentationStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case candidateBar
    case timeline
    public var id: String { rawValue }
    public static let candidatePageSize = 10
    /// Default for fresh installs and for unrecognized saved values. Users who
    /// explicitly chose Timeline keep the stored "timeline" preference.
    public static let defaultStyle: ClipboardPresentationStyle = .candidateBar
}

/// Candidate keys are local to the visible panel. Never consume application
/// shortcuts or turn an unrelated character into a paste command.
public enum CandidateKeyAction: Equatable, Sendable {
    case choose(Int), move(Int), nextPage, previousPage, activate, close

    public static func resolve(keyCode: UInt16, characters: String, modifiers: ShortcutModifiers) -> Self? {
        guard modifiers.intersection([.command, .control, .option]).isEmpty else { return nil }
        if keyCode == 48 { return modifiers.contains(.shift) ? .previousPage : .nextPage }
        guard !modifiers.contains(.shift) else { return nil }
        switch keyCode {
        case 36, 76: return .activate
        case 53: return .close
        case 123: return .previousPage
        case 124: return .nextPage
        case 126: return .move(-1)
        case 125: return .move(1)
        default:
            guard characters.count == 1, let number = Int(characters), (0...9).contains(number) else { return nil }
            return .choose(number == 0 ? 9 : number - 1)
        }
    }

    public static func movedIndex(current: Int?, delta: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        return min(max((current ?? 0) + delta, 0), count - 1)
    }
}

/// Bounded paging, shared by keyboard and mouse controls. A short last page is
/// never filled with repeated clips, and end-of-history does not loop silently.
public enum CandidatePagination {
    public static func pageCount(itemCount: Int) -> Int {
        guard itemCount > 0 else { return 1 }
        return (itemCount - 1) / ClipboardPresentationStyle.candidatePageSize + 1
    }

    public static func clampedPage(_ page: Int, itemCount: Int) -> Int {
        min(max(0, page), pageCount(itemCount: itemCount) - 1)
    }

    public static func range(page: Int, itemCount: Int) -> Range<Int> {
        let count = max(0, itemCount)
        let start = clampedPage(page, itemCount: count) * ClipboardPresentationStyle.candidatePageSize
        return start..<(start + min(ClipboardPresentationStyle.candidatePageSize, count - start))
    }
}
