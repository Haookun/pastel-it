import AppKit

/// Traced egg-tart template for the Pastel it！ menu bar.
/// The system handles light/dark tinting. Holding ⌘C or ⌘V thickens the
/// silhouette slightly, retaining copy/paste feedback without tiny letters.
@MainActor
final class MenuBarTartIcon {
    enum Key {
        case c
        case v
    }

    static let preferredSize = NSSize(width: 24, height: 22)

    private var cPressed = false
    private var vPressed = false

    /// Called whenever the template image should be reapplied to the status button.
    var onImageChange: ((NSImage) -> Void)?

    func currentImage() -> NSImage {
        Self.makeTemplateImage(cPressed: cPressed, vPressed: vPressed)
    }

    func publish() {
        onImageChange?(currentImage())
    }

    /// Hold → solid; release → hollow. No timed flash.
    func setPressed(_ pressed: Bool, for key: Key) {
        switch key {
        case .c:
            guard cPressed != pressed else { return }
            cPressed = pressed
        case .v:
            guard vPressed != pressed else { return }
            vPressed = pressed
        }
        publish()
    }

    static func makeTemplateImage(cPressed: Bool, vPressed: Bool) -> NSImage {
        let size = preferredSize
        let image = NSImage(size: size, flipped: false) { bounds in
            drawKeycaps(in: bounds, cPressed: cPressed, vPressed: vPressed)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawKeycaps(in bounds: NSRect, cPressed: Bool, vPressed: Bool) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        defer { context.restoreGState() }
        let scale = min(bounds.width, bounds.height) / 24
        context.translateBy(x: bounds.midX - 12 * scale, y: bounds.midY + 12 * scale)
        context.scaleBy(x: scale, y: -scale)
        context.setFillColor(NSColor.black.cgColor)
        let outline = MenuBarTartArtwork.outline()
        context.addPath(outline)
        context.drawPath(using: .eoFill)
        if cPressed || vPressed {
            context.setStrokeColor(NSColor.black.cgColor)
            context.setLineWidth(cPressed && vPressed ? 0.7 : 0.45)
            context.setLineJoin(.round)
            context.addPath(outline)
            context.strokePath()
        }
    }
}
