import AppKit
import SwiftUI

/// A local monitor affects only this strip, preserving native horizontal gestures
/// and any nested vertical text/preview scrolling.
struct TimelineWheelScrolling: NSViewRepresentable {
    var onViewportChange: ((CGFloat) -> Void)?
    func makeNSView(context: Context) -> WheelView {
        let view = WheelView()
        view.onViewportChange = onViewportChange
        return view
    }
    func updateNSView(_ view: WheelView, context: Context) { view.onViewportChange = onViewportChange }
    static func dismantleNSView(_ view: WheelView, coordinator: ()) { view.stop() }

    final class WheelView: NSView {
        private var monitor: Any?
        var onViewportChange: ((CGFloat) -> Void)?
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stop()
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil, let clip = self.enclosingScrollView?.contentView else { return }
                clip.postsBoundsChangedNotifications = true
                NotificationCenter.default.addObserver(self, selector: #selector(self.boundsChanged),
                    name: NSView.boundsDidChangeNotification, object: clip)
            }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handle(event) == true ? nil : event
            }
        }

        func stop() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            NotificationCenter.default.removeObserver(self)
        }

        @objc private func boundsChanged(_ notification: Notification) {
            guard let offset = enclosingScrollView?.contentView.bounds.origin.x else { return }
            onViewportChange?(offset)
        }

        private func handle(_ event: NSEvent) -> Bool {
            guard let window, event.window === window, let scroll = enclosingScrollView,
                  abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX),
                  !event.modifierFlags.contains(.command),
                  scroll.bounds.contains(scroll.convert(event.locationInWindow, from: nil)) else { return false }
            let point = scroll.convert(event.locationInWindow, from: nil)
            if let nested = scroll.contentView.hitTest(point)?.enclosingScrollView, nested !== scroll { return false }
            Self.scroll(delta: -event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 1 : 24), in: scroll)
            return true
        }

        static func scroll(delta: CGFloat, in scroll: NSScrollView) {
            guard delta.isFinite, let document = scroll.documentView else { return }
            let minimum = -scroll.contentInsets.left
            let maximum = max(minimum, document.frame.width - scroll.contentView.bounds.width + scroll.contentInsets.right)
            var origin = scroll.contentView.bounds.origin
            origin.x = min(maximum, max(minimum, origin.x + delta))
            scroll.contentView.scroll(to: origin)
            scroll.reflectScrolledClipView(scroll.contentView)
        }
    }
}
