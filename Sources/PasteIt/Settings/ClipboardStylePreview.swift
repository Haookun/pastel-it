import SwiftUI
import PasteItCore

/// Minimal vector preview of the two clipboard presentations, drawn with
/// SwiftUI shapes only — no real history, no new dependencies. The highlight
/// motion plays for a fixed, finite duration, then the preview settles into a
/// static frame so the settings window does not keep a live timer forever;
/// picking a style replays it. With Reduce Motion enabled the periodic clock
/// never starts and a static frame is shown.
struct ClipboardStylePreview: View {
    let style: ClipboardPresentationStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Start of the current finite playback; changing it replays the animation.
    @State private var animationStart = Date()
    /// Flips to false at the end of the finite run, swapping the live
    /// TimelineView for a static Canvas so no timer keeps ticking.
    @State private var animating = true

    /// Fixed design canvas; everything is drawn in these coordinates and the
    /// whole canvas is scaled once (uniformly) to fit the actual view size.
    private let designSize = CGSize(width: 480, height: 300) // 8:5

    /// One full out-and-back loop of the highlight motion, in seconds.
    private let cycleLength: Double = 4.0
    /// Total playback time; the loop length divides it so the final frame is
    /// exactly the loop origin (phase 0), which is also the static frame.
    private let animationDuration: Double = 8.0
    /// Settled frame once the finite playback ends (loop origin = seamless stop).
    private let settledPhase: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if reduceMotion {
                    Canvas { context, size in
                        draw(context: &context, size: size, phase: 0.35)
                    }
                } else if animating {
                    // Pauses automatically when the view leaves the window, and
                    // is torn down entirely once `animating` flips to false.
                    SwiftUI.TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        Canvas { context, size in
                            let elapsed = min(timeline.date.timeIntervalSince(animationStart), animationDuration)
                            let phase = elapsed.truncatingRemainder(dividingBy: cycleLength) / cycleLength
                            draw(context: &context, size: size, phase: phase)
                        }
                    }
                    .task(id: animationStart) {
                        try? await Task.sleep(for: .seconds(animationDuration))
                        guard !Task.isCancelled else { return }
                        animating = false
                    }
                } else {
                    Canvas { context, size in
                        draw(context: &context, size: size, phase: settledPhase)
                    }
                }
            }
            // Fixed 8:5 box, capped so it never stretches across a wide Form,
            // centered, and shrinks proportionally on narrower Forms.
            .aspectRatio(designSize.width / designSize.height, contentMode: .fit)
            .frame(maxWidth: 410)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
            // Re-selecting a style replays the finite animation.
            .onChange(of: style) { _, _ in
                animationStart = Date()
                animating = true
            }

            Text(style == .timeline
                 ? L10n.tr("clipboard.style.previewTimeline", default: "Cards along the bottom of the screen.")
                 : L10n.tr("clipboard.style.previewCandidate", default: "A compact list next to your text cursor."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .animation(nil, value: style)
        }
    }

    // MARK: - Drawing

    private func draw(context: inout GraphicsContext, size: CGSize, phase: Double) {
        // One uniform transform for the fixed design canvas — corner radii,
        // line widths and all offsets scale together, so nothing distorts.
        let scale = min(size.width / designSize.width, size.height / designSize.height)
        context.translateBy(
            x: (size.width - designSize.width * scale) / 2,
            y: (size.height - designSize.height * scale) / 2
        )
        context.scaleBy(x: scale, y: scale)

        switch style {
        case .timeline: drawTimeline(context: &context, phase: phase)
        case .candidateBar: drawCandidateBar(context: &context, phase: phase)
        }
    }

    /// The host-app window in design coordinates.
    private var windowRect: CGRect { CGRect(x: 24, y: 18, width: 432, height: 264) }

    /// A tiny host-app window: outline, title bar dots, body text lines and a
    /// text caret. Returns the caret rect so each style can anchor its UI to it.
    /// The caret is always drawn so it stays visible in the Reduce Motion
    /// static frame as well.
    private func drawAppWindow(context: inout GraphicsContext, caretBlink: Double) -> CGRect {
        let windowRect = self.windowRect
        let windowShape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        context.fill(windowShape.path(in: windowRect), with: .color(.primary.opacity(0.04)))
        context.stroke(windowShape.path(in: windowRect), with: .color(.primary.opacity(0.20)), lineWidth: 1)

        // Title bar dots.
        for dot in 0..<3 {
            let rect = CGRect(x: windowRect.minX + 12 + CGFloat(dot) * 12, y: windowRect.minY + 10, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(.primary.opacity(0.25)))
        }

        // Body text lines; the caret sits at the end of the second line, far
        // enough left/up that the candidate popup fits below-right of it.
        let lineWidths: [CGFloat] = [170, 120, 150]
        let lineX = windowRect.minX + 18
        var caretRect = CGRect.zero
        for (index, width) in lineWidths.enumerated() {
            let y = windowRect.minY + 32 + CGFloat(index) * 16
            let rect = CGRect(x: lineX, y: y, width: width, height: 4)
            context.fill(
                RoundedRectangle(cornerRadius: 2, style: .continuous).path(in: rect),
                with: .color(.primary.opacity(0.22))
            )
            if index == 1 {
                caretRect = CGRect(x: lineX + width + 4, y: y - 4, width: 2, height: 12)
            }
        }

        // Soft blink while animating; never fully hidden in the static frame.
        let caretOpacity = 0.55 + 0.45 * caretBlink
        context.fill(Path(caretRect), with: .color(.accentColor.opacity(caretOpacity)))
        return caretRect
    }

    /// Timeline: the card strip sits along the bottom edge of the app window.
    /// Cards keep the real presentation's near-square proportions (~238×232).
    private func drawTimeline(context: inout GraphicsContext, phase: Double) {
        let blink = 0.5 + 0.5 * sin(phase * 4 * .pi)
        _ = drawAppWindow(context: &context, caretBlink: blink)

        let windowRect = self.windowRect
        let cardCount = 3
        let spacing: CGFloat = 10
        // Near-square cards, like the real ~238×232 timeline cards.
        let cardSize = CGSize(width: 58, height: 56)
        let stripWidth = CGFloat(cardCount) * cardSize.width + CGFloat(cardCount - 1) * spacing
        let top = windowRect.maxY - 12 - cardSize.height
        // Gentle ping-pong drift of the strip plus a moving highlight.
        let drift = sin(phase * 2 * .pi) * 4
        let highlightIndex = Int((phase * Double(cardCount)).rounded()) % cardCount
        let startX = windowRect.midX - stripWidth / 2

        for index in 0..<cardCount {
            let x = startX + CGFloat(index) * (cardSize.width + spacing) + drift
            let rect = CGRect(origin: CGPoint(x: x, y: top), size: cardSize)
            let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
            context.fill(shape.path(in: rect), with: .color(.primary.opacity(0.10)))
            if index == highlightIndex {
                context.stroke(shape.path(in: rect), with: .color(.accentColor), lineWidth: 1.5)
            }
            // Fake text lines inside each card.
            for line in 0..<3 {
                let lineRect = CGRect(
                    x: rect.minX + 8,
                    y: rect.minY + 10 + CGFloat(line) * 11,
                    width: (rect.width - 16) * (line == 0 ? 1 : (line == 1 ? 0.7 : 0.45)),
                    height: 3.5
                )
                context.fill(
                    RoundedRectangle(cornerRadius: 1.75, style: .continuous).path(in: lineRect),
                    with: .color(.primary.opacity(0.25))
                )
            }
        }
    }

    /// Candidate bar: a 10-row popup drops down beside the text caret. The
    /// popup keeps the real window's near-square proportions (~420×393),
    /// drawn here at ~150×140 including a small top bar.
    private func drawCandidateBar(context: inout GraphicsContext, phase: Double) {
        let blink = 0.5 + 0.5 * sin(phase * 4 * .pi)
        let caretRect = drawAppWindow(context: &context, caretBlink: blink)

        let windowRect = self.windowRect
        let rowCount = 10
        // ~420×393 real window → near-square 150×140 popup.
        let listSize = CGSize(width: 150, height: 140)
        let topBarHeight: CGFloat = 12
        // Anchor below-right of the caret, clamped inside the window outline.
        let listX = min(caretRect.maxX + 6, windowRect.maxX - 8 - listSize.width)
        let listTop = min(caretRect.maxY + 6, windowRect.maxY - 8 - listSize.height)
        // A subtle slide-in bounce so the popup feels alive without big motion.
        let slide = (1 - min(1, phase * 6)) * 3

        let popupRect = CGRect(x: listX, y: listTop + slide, width: listSize.width, height: listSize.height)
        let popupShape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        context.fill(popupShape.path(in: popupRect), with: .color(.primary.opacity(0.06)))
        context.stroke(popupShape.path(in: popupRect), with: .color(.primary.opacity(0.18)), lineWidth: 1)

        // Small top bar.
        let topBarRect = CGRect(
            x: popupRect.minX + 8,
            y: popupRect.minY + 5,
            width: popupRect.width - 16,
            height: topBarHeight - 8
        )
        context.fill(
            RoundedRectangle(cornerRadius: 2, style: .continuous).path(in: topBarRect),
            with: .color(.primary.opacity(0.16))
        )

        let rowsTop = popupRect.minY + topBarHeight + 4
        let rowHeight = (popupRect.maxY - 6 - rowsTop) / CGFloat(rowCount)
        let selectedIndex = Int(phase * Double(rowCount)) % rowCount
        for row in 0..<rowCount {
            let rect = CGRect(
                x: popupRect.minX + 6,
                y: rowsTop + CGFloat(row) * rowHeight + 0.5,
                width: popupRect.width - 12,
                height: rowHeight - 1
            )
            let shape = RoundedRectangle(cornerRadius: 2, style: .continuous)
            if row == selectedIndex {
                context.fill(shape.path(in: rect), with: .color(.accentColor))
            } else {
                context.fill(shape.path(in: rect), with: .color(.primary.opacity(0.10)))
            }
            // Fake label line.
            let labelRect = CGRect(
                x: rect.minX + 8,
                y: rect.midY - 1,
                width: (rect.width - 16) * (row == selectedIndex ? 0.8 : 0.55),
                height: 2
            )
            context.fill(
                RoundedRectangle(cornerRadius: 1, style: .continuous).path(in: labelRect),
                with: .color(row == selectedIndex ? .white.opacity(0.85) : .primary.opacity(0.25))
            )
        }
    }
}
