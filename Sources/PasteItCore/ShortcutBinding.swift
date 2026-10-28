import Foundation

public enum ShortcutAction: String, CaseIterable, Codable, Sendable, Identifiable {
    case timeline, quickPaste
    public var id: String { rawValue }

    public var defaultBinding: ShortcutBinding {
        switch self {
        case .timeline: ShortcutBinding(keyCode: 8, modifiers: [.command, .shift], key: "C")
        case .quickPaste: ShortcutBinding(keyCode: 9, modifiers: [.command, .shift], key: "V")
        }
    }
}

public struct ShortcutModifiers: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let control = Self(rawValue: 1)
    public static let option = Self(rawValue: 2)
    public static let shift = Self(rawValue: 4)
    public static let command = Self(rawValue: 8)
    public static let all: Self = [.control, .option, .shift, .command]
}

public struct ShortcutBinding: Codable, Equatable, Sendable {
    public let keyCode: UInt32
    public let modifiers: ShortcutModifiers
    public let key: String

    public init(keyCode: UInt32, modifiers: ShortcutModifiers, key: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.key = key
    }

    public var display: String {
        (modifiers.contains(.control) ? "⌃" : "") +
        (modifiers.contains(.option) ? "⌥" : "") +
        (modifiers.contains(.shift) ? "⇧" : "") +
        (modifiers.contains(.command) ? "⌘" : "") + key
    }

    public func matches(_ other: Self) -> Bool {
        keyCode == other.keyCode && modifiers == other.modifiers
    }

    public var isValid: Bool {
        keyCode <= 126 && !key.isEmpty && key.count <= 12 &&
        modifiers.isSubset(of: .all) &&
        !modifiers.intersection([.command, .control, .option]).isEmpty &&
        // Escape cancels recording; modifier-only keys cannot form a shortcut.
        ![53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(keyCode)
    }

    public var isReserved: Bool {
        // Keep editing, clipboard, window and application commands usable.
        if modifiers == .command {
            return [0, 6, 7, 8, 9, 12, 13, 14, 38, 40, 43, 46, 4].contains(keyCode)
        }
        return modifiers == [.command, .shift] && keyCode == 17 // Pause Capture
    }
}

public struct ShortcutConfiguration: Codable, Equatable, Sendable {
    public var timeline: ShortcutBinding?
    public var quickPaste: ShortcutBinding?

    public init(timeline: ShortcutBinding?, quickPaste: ShortcutBinding? = nil) {
        self.timeline = timeline
        self.quickPaste = quickPaste
    }

    public static let defaults = Self(timeline: ShortcutAction.timeline.defaultBinding,
                                      quickPaste: ShortcutAction.quickPaste.defaultBinding)

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, timeline, quickPaste, stack, plainPaste
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        timeline = try values.decodeIfPresent(ShortcutBinding.self, forKey: .timeline)
        quickPaste = try values.decodeIfPresent(ShortcutBinding.self, forKey: .quickPaste)
        let version = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0
        if version < 2 {
            let stack = try values.decodeIfPresent(ShortcutBinding.self, forKey: .stack)
            let plain = try values.decodeIfPresent(ShortcutBinding.self, forKey: .plainPaste)
            let oldTimeline = ShortcutBinding(keyCode: 9, modifiers: [.command, .shift], key: "V")
            let oldPlain = ShortcutBinding(keyCode: 9, modifiers: [.command, .control], key: "V")
            // Migrate only the complete factory configuration. Preserve custom
            // and explicitly cleared bindings, including a custom timeline ⇧⌘V.
            if timeline?.matches(oldTimeline) == true,
               stack?.matches(ShortcutAction.timeline.defaultBinding) == true,
               plain?.matches(oldPlain) == true {
                timeline = ShortcutAction.timeline.defaultBinding
                if quickPaste == nil { quickPaste = ShortcutAction.quickPaste.defaultBinding }
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(2, forKey: .schemaVersion)
        try values.encodeIfPresent(timeline, forKey: .timeline)
        try values.encodeIfPresent(quickPaste, forKey: .quickPaste)
    }

    public subscript(action: ShortcutAction) -> ShortcutBinding? {
        get {
            switch action {
            case .timeline: timeline
            case .quickPaste: quickPaste
            }
        }
        set {
            switch action {
            case .timeline: timeline = newValue
            case .quickPaste: quickPaste = newValue
            }
        }
    }

    public var isValid: Bool {
        let values = ShortcutAction.allCases.compactMap { self[$0] }
        guard values.allSatisfy({ $0.isValid && !$0.isReserved }) else { return false }
        for (index, binding) in values.enumerated() {
            if values.dropFirst(index + 1).contains(where: { binding.matches($0) }) { return false }
        }
        return true
    }

    public static func load(from defaults: UserDefaults) -> Self {
        guard let data = defaults.data(forKey: "globalKeyboardShortcuts"),
              let value = try? JSONDecoder().decode(Self.self, from: data), value.isValid else {
            return .defaults
        }
        return value
    }

    public func save(to defaults: UserDefaults) {
        guard isValid, let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: "globalKeyboardShortcuts")
    }
}
