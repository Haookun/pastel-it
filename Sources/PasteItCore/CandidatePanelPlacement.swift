import Foundation

/// AppKit screen coordinates, including displays left of or above the primary.
public enum CandidatePanelPlacement {
    public static func appKitRect(fromAccessibility rect: CGRect, primaryScreenTop: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryScreenTop - rect.maxY, width: rect.width, height: rect.height)
    }

    public static func frame(anchor: CGRect, size: CGSize, visibleFrame: CGRect, gap: CGFloat = 6) -> CGRect {
        let safe = visibleFrame.insetBy(dx: 8, dy: 8)
        let width = min(size.width, safe.width)
        let height = min(size.height, safe.height)
        let below = anchor.minY - gap - height
        let above = anchor.maxY + gap
        // Prefer below, then above; when neither fits choose the roomier side.
        let y: CGFloat
        if below >= safe.minY { y = below }
        else if above + height <= safe.maxY { y = above }
        else { y = anchor.minY - safe.minY >= safe.maxY - anchor.maxY ? below : above }
        return CGRect(x: min(max(anchor.minX, safe.minX), safe.maxX - width),
                      y: min(max(y, safe.minY), safe.maxY - height), width: width, height: height)
    }
}
