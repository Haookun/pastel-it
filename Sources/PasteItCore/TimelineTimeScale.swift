import Foundation

/// Copy time is independent of the timeline's promotion and pinned-item ordering.
public struct TimelineTimeScale: Sendable {
    public struct Entry: Equatable, Sendable {
        public let id: UUID
        public let date: Date
        public init(id: UUID, date: Date) { self.id = id; self.date = date }
    }

    public let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries.filter { $0.date.timeIntervalSinceReferenceDate.isFinite }.sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    /// Latest on the left, oldest on the right, matching the history strip.
    public func fraction(for date: Date) -> Double {
        guard let newest = entries.first?.date, let oldest = entries.last?.date else { return 0 }
        let span = newest.timeIntervalSince(oldest)
        guard span > 0, date.timeIntervalSinceReferenceDate.isFinite else { return 0.5 }
        return min(1, max(0, newest.timeIntervalSince(date) / span))
    }

    public func nearest(to fraction: Double) -> Entry? {
        guard let newest = entries.first?.date, let oldest = entries.last?.date else { return nil }
        let bounded = fraction.isFinite ? min(1, max(0, fraction)) : 0
        let target = newest.addingTimeInterval(-bounded * newest.timeIntervalSince(oldest))
        var low = 0, high = entries.count
        while low < high {
            let middle = (low + high) / 2
            if entries[middle].date > target { low = middle + 1 }
            else { high = middle }
        }
        guard low > 0 else { return entries.first }
        guard low < entries.count else { return entries.last }
        let newer = entries[low - 1], older = entries[low]
        return abs(newer.date.timeIntervalSince(target)) <= abs(older.date.timeIntervalSince(target)) ? newer : older
    }
}
