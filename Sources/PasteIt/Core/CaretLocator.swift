import ApplicationServices
import Foundation
import PasteItCore

/// Read geometry only. No selected text/value, no permission prompts, and no
/// polling after our candidate panel takes keyboard focus.
enum CaretLocator {
    static func capture(processID: pid_t, primaryScreenTop: CGFloat) async -> CGRect? {
        await Task.detached(priority: .userInitiated) {
            guard AXIsProcessTrusted() else { return nil }
            let application = AXUIElementCreateApplication(processID)
            AXUIElementSetMessagingTimeout(application, 0.15)
            var focusedValue: CFTypeRef?
            guard AXUIElementCopyAttributeValue(application, kAXFocusedUIElementAttribute as CFString, &focusedValue) == .success,
                  let focusedValue, CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else { return nil }
            let focused = unsafeDowncast(focusedValue, to: AXUIElement.self)
            AXUIElementSetMessagingTimeout(focused, 0.15)
            var subrole: CFTypeRef?
            AXUIElementCopyAttributeValue(focused, kAXSubroleAttribute as CFString, &subrole)
            guard subrole as? String != kAXSecureTextFieldSubrole else { return nil }
            var selectedValue: CFTypeRef?
            guard AXUIElementCopyAttributeValue(focused, kAXSelectedTextRangeAttribute as CFString, &selectedValue) == .success,
                  let selectedValue, CFGetTypeID(selectedValue) == AXValueGetTypeID() else { return nil }
            let selected = unsafeDowncast(selectedValue, to: AXValue.self)
            var range = CFRange()
            guard AXValueGetType(selected) == .cfRange, AXValueGetValue(selected, .cfRange, &range), range.location >= 0 else { return nil }
            // For a selection use its start, never the bounding box of the full
            // selection. Some clients only expose bounds for a real character.
            let attempts = [(CFRange(location: range.location, length: 0), false),
                            (CFRange(location: range.location, length: 1), false)] +
                (range.location > 0 ? [(CFRange(location: range.location - 1, length: 1), true)] : [])
            for (requested, trailing) in attempts {
                var requested = requested
                guard let parameter = AXValueCreate(.cfRange, &requested) else { continue }
                var boundsValue: CFTypeRef?
                guard AXUIElementCopyParameterizedAttributeValue(focused, kAXBoundsForRangeParameterizedAttribute as CFString,
                    parameter, &boundsValue) == .success,
                      let boundsValue, CFGetTypeID(boundsValue) == AXValueGetTypeID() else { continue }
                let bounds = unsafeDowncast(boundsValue, to: AXValue.self)
                var rect = CGRect.zero
                guard AXValueGetType(bounds) == .cgRect, AXValueGetValue(bounds, .cgRect, &rect),
                      rect.origin.x.isFinite, rect.origin.y.isFinite, rect.width.isFinite, rect.height.isFinite,
                      rect.width >= 0, rect.height > 0 else { continue }
                rect = CGRect(x: trailing ? rect.maxX : rect.minX, y: rect.minY, width: 0, height: rect.height)
                return CandidatePanelPlacement.appKitRect(fromAccessibility: rect, primaryScreenTop: primaryScreenTop)
            }
            return nil
        }.value
    }
}
