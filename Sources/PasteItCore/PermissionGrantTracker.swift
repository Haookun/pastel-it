/// Prompts once for a permission newly granted during this process, never at
/// startup for permission the app already had. Revocation alone needs no prompt.
public struct PermissionGrantTracker: Sendable {
    private var granted: Bool
    private var prompted = false
    public init(granted: Bool) { self.granted = granted }
    public mutating func update(granted newValue: Bool) -> Bool {
        let shouldPrompt = newValue && !granted && !prompted
        granted = newValue
        if shouldPrompt { prompted = true }
        return shouldPrompt
    }
}
