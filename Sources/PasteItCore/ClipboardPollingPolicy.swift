/// Keep persisted or externally edited preferences from creating a busy timer.
public enum ClipboardPollingPolicy {
    public static func interval(_ requested: Double) -> Double {
        guard requested.isFinite else { return 0.35 }
        return min(2, max(0.2, requested))
    }
}
