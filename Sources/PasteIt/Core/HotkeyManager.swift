import AppKit
import Carbon
import Combine
import PasteItCore

/// Carbon registrations work across apps without Accessibility permission.
@MainActor
final class HotkeyManager: ObservableObject {
    @Published private(set) var shortcuts: ShortcutConfiguration
    @Published private(set) var errorMessage: String?
    private let defaults: UserDefaults
    private let showTimeline: () -> Void
    private let togglePasteStack: () -> Void
    private let pastePlain: () -> Bool
    private let editSelected: () -> Bool
    private let quickPaste: () -> Bool
    private var quickPasteEnabled: Bool
    private var eventHandler: EventHandlerRef?
    private var hotkeys: [ShortcutAction: EventHotKeyRef] = [:]
    private var localMonitor: Any?
    private var recording = false

    init(defaults: UserDefaults = .standard,
         showTimeline: @escaping () -> Void,
         togglePasteStack: @escaping () -> Void,
         pastePlain: @escaping () -> Bool,
         editSelected: @escaping () -> Bool,
         quickPaste: @escaping () -> Bool = { false }) {
        self.defaults = defaults
        self.shortcuts = .load(from: defaults)
        self.showTimeline = showTimeline
        self.togglePasteStack = togglePasteStack
        self.pastePlain = pastePlain
        self.editSelected = editSelected
        self.quickPaste = quickPaste
        self.quickPasteEnabled = defaults.bool(forKey: "quickPasteEnabled")
    }

    func start() {
        stop()
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context, let event else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(context).takeUnretainedValue()
            return manager.handleCarbonEvent(event)
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        guard status == noErr else {
            errorMessage = Self.unavailableMessage
            return
        }
        if !register(shortcuts) { errorMessage = Self.unavailableMessage }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, !self.recording else { return event }
            return self.handleLocal(event) ? nil : event
        }
    }

    func stop() {
        unregister()
        if let eventHandler { RemoveEventHandler(eventHandler) }
        eventHandler = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        localMonitor = nil
    }

    func beginRecording() {
        recording = true
        unregister()
    }

    func endRecording() {
        guard recording else { return }
        recording = false
        unregister()
        if !register(shortcuts) { errorMessage = Self.unavailableMessage }
    }

    @discardableResult
    func set(_ binding: ShortcutBinding, for action: ShortcutAction) -> Bool {
        guard binding.isValid, !binding.isReserved else {
            errorMessage = L10n.tr("shortcuts.invalid", default: "Use a key with Command, Control, or Option. Standard editing and app commands are reserved.")
            return false
        }
        guard !ShortcutAction.allCases.contains(where: { $0 != action && shortcuts[$0]?.matches(binding) == true }) else {
            errorMessage = L10n.tr("shortcuts.duplicate", default: "This shortcut is already assigned to another action.")
            return false
        }
        var proposed = shortcuts
        proposed[action] = binding
        return apply(proposed)
    }

    @discardableResult
    func clear(_ action: ShortcutAction) -> Bool {
        var proposed = shortcuts
        proposed[action] = nil
        guard apply(proposed) else { return false }
        return action == .quickPaste ? setQuickPasteEnabled(false) : true
    }

    @discardableResult
    func resetDefaults() -> Bool {
        guard apply(.defaults) else { return false }
        return setQuickPasteEnabled(false)
    }

    @discardableResult
    func setQuickPasteEnabled(_ enabled: Bool) -> Bool {
        if enabled, shortcuts.quickPaste == nil,
           !set(ShortcutAction.quickPaste.defaultBinding, for: .quickPaste) { return false }
        let previous = quickPasteEnabled
        if eventHandler == nil {
            quickPasteEnabled = enabled
            defaults.set(enabled, forKey: "quickPasteEnabled")
            return true
        }
        unregister()
        quickPasteEnabled = enabled
        if register(shortcuts) {
            defaults.set(enabled, forKey: "quickPasteEnabled")
            errorMessage = nil
            return true
        }
        unregister()
        quickPasteEnabled = previous
        _ = register(shortcuts)
        errorMessage = Self.unavailableMessage
        return false
    }

    func clearError() { errorMessage = nil }

    private func apply(_ proposed: ShortcutConfiguration) -> Bool {
        guard proposed.isValid else { return false }
        if eventHandler == nil {
            shortcuts = proposed
            proposed.save(to: defaults)
            errorMessage = nil
            return true
        }
        defer { if recording { unregister() } }
        unregister()
        if register(proposed) {
            shortcuts = proposed
            proposed.save(to: defaults)
            errorMessage = nil
            return true
        }
        unregister()
        // A failed update never replaces the saved configuration.
        let restored = register(shortcuts)
        errorMessage = restored
            ? L10n.tr("shortcuts.unavailable", default: "macOS could not register this shortcut. It may be in use. Your previous shortcuts were kept.")
            : Self.unavailableMessage
        return false
    }

    private static var unavailableMessage: String {
        L10n.tr("shortcuts.registrationFailed", default: "Some shortcuts could not be registered. Choose another combination; all actions remain available from the menu.")
    }

    private func unregister() {
        for ref in hotkeys.values { UnregisterEventHotKey(ref) }
        hotkeys.removeAll()
    }

    private func register(_ configuration: ShortcutConfiguration) -> Bool {
        var succeeded = true
        for (index, action) in ShortcutAction.allCases.enumerated() {
            if action == .quickPaste && !quickPasteEnabled { continue }
            var ref: EventHotKeyRef?
            guard let binding = configuration[action] else { continue }
            let status = RegisterEventHotKey(binding.keyCode, binding.carbonModifiers,
                EventHotKeyID(signature: 0x70617363, id: UInt32(index + 1)),
                GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref { hotkeys[action] = ref }
            else { succeeded = false }
        }
        return succeeded
    }

    nonisolated private func handleCarbonEvent(_ event: EventRef) -> OSStatus {
        var id = EventHotKeyID()
        guard GetEventParameter(event, EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id) == noErr,
            let action = ShortcutAction.allCases.enumerated().first(where: { UInt32($0.offset + 1) == id.id })?.element else {
            return OSStatus(eventNotHandledErr)
        }
        Task { @MainActor in
            guard !self.recording, self.shortcuts[action] != nil else { return }
            _ = self.perform(action)
        }
        return noErr
    }

    private func perform(_ action: ShortcutAction) -> Bool {
        switch action {
        case .timeline: showTimeline(); return true
        case .stack: togglePasteStack(); return true
        case .plainPaste: return pastePlain()
        case .quickPaste: return quickPasteEnabled ? quickPaste() : false
        }
    }

    private func handleLocal(_ event: NSEvent) -> Bool {
        let binding = ShortcutBinding(event: event)
        if let action = ShortcutAction.allCases.first(where: { shortcuts[$0]?.matches(binding) == true }) {
            return perform(action)
        }
        if event.keyCode == UInt16(kVK_ANSI_E), binding.modifiers == .command {
            return editSelected()
        }
        return false
    }
}

extension ShortcutBinding {
    init(event: NSEvent) {
        let flags = event.modifierFlags
        var modifiers: ShortcutModifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        let special: [UInt16: String] = [36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            115: "↖", 116: "⇞", 117: "⌦", 119: "↘", 121: "⇟", 123: "←", 124: "→", 125: "↓", 126: "↑"]
        let functionKeys: [UInt16: String] = [122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20"]
        self.init(keyCode: UInt32(event.keyCode), modifiers: modifiers,
                  key: special[event.keyCode] ?? functionKeys[event.keyCode] ??
                    event.characters(byApplyingModifiers: [])?.uppercased() ?? "")
    }

    var eventModifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers.contains(.command) { flags.insert(.command) }
        if modifiers.contains(.control) { flags.insert(.control) }
        if modifiers.contains(.option) { flags.insert(.option) }
        if modifiers.contains(.shift) { flags.insert(.shift) }
        return flags
    }

    var carbonModifiers: UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) { flags |= UInt32(cmdKey) }
        if modifiers.contains(.control) { flags |= UInt32(controlKey) }
        if modifiers.contains(.option) { flags |= UInt32(optionKey) }
        if modifiers.contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }
}
