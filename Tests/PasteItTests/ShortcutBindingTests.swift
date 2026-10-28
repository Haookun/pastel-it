import Foundation
import Testing
@testable import PasteItCore

struct ShortcutBindingTests {
    @Test func defaultAndDuplicateValidation() throws {
        #expect(ShortcutConfiguration.defaults.isValid)
        var config = ShortcutConfiguration.defaults
        config.quickPaste = config.timeline
        #expect(!config.isValid)
        // Display text cannot hide a physical key conflict.
        let timeline = try #require(config.timeline)
        config.quickPaste = ShortcutBinding(keyCode: timeline.keyCode,
                                       modifiers: timeline.modifiers, key: "Different")
        #expect(!config.isValid)
    }

    @Test func invalidAndReservedBindings() {
        #expect(!ShortcutBinding(keyCode: 9, modifiers: [], key: "V").isValid)
        #expect(!ShortcutBinding(keyCode: 56, modifiers: .command, key: "Shift").isValid)
        #expect(ShortcutBinding(keyCode: 9, modifiers: .command, key: "V").isReserved)
        #expect(ShortcutBinding(keyCode: 17, modifiers: [.command, .shift], key: "T").isReserved)
        #expect(!ShortcutBinding(keyCode: 9, modifiers: [.command, .option], key: "V").isReserved)
    }

    @Test func persistenceResetAndCorruptFallback() throws {
        let name = "PasteIt.Shortcuts.Tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        #expect(ShortcutConfiguration.load(from: defaults) == .defaults)
        var changed = ShortcutConfiguration.defaults
        changed.timeline = ShortcutBinding(keyCode: 9, modifiers: [.command, .option], key: "V")
        changed.save(to: defaults)
        #expect(ShortcutConfiguration.load(from: defaults) == changed)
        ShortcutConfiguration.defaults.save(to: defaults)
        #expect(ShortcutConfiguration.load(from: defaults) == .defaults)
        defaults.set(Data("bad json".utf8), forKey: "globalKeyboardShortcuts")
        #expect(ShortcutConfiguration.load(from: defaults) == .defaults)
        changed.quickPaste = changed.timeline
        defaults.set(try JSONEncoder().encode(changed), forKey: "globalKeyboardShortcuts")
        #expect(ShortcutConfiguration.load(from: defaults) == .defaults)
    }

    @Test func clearedShortcutsPersistWithoutRestoringDefaults() throws {
        let name = "PasteIt.ClearedShortcuts.Tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        var config = ShortcutConfiguration.defaults
        for action in ShortcutAction.allCases {
            config[action] = nil
            #expect(config.isValid)
            config.save(to: defaults)
            let reloaded = ShortcutConfiguration.load(from: defaults)
            #expect(reloaded == config)
            #expect(reloaded[action] == nil)
        }
        // Multiple unassigned actions are valid; defaults can still be restored.
        #expect(ShortcutAction.allCases.allSatisfy { config[$0] == nil })
        ShortcutConfiguration.defaults.save(to: defaults)
        #expect(ShortcutConfiguration.load(from: defaults) == .defaults)
    }

    @Test func clearingOneShortcutKeepsOtherActionsAndExistingPreferences() throws {
        let data = try JSONEncoder().encode(ShortcutConfiguration.defaults)
        var config = try JSONDecoder().decode(ShortcutConfiguration.self, from: data)
        config.timeline = nil
        #expect(config.isValid)
        #expect(config.quickPaste == ShortcutAction.quickPaste.defaultBinding)
        config.timeline = config.quickPaste
        #expect(!config.isValid)
    }

    @Test func migratesOnlyTheLegacyFactoryShortcuts() throws {
        let oldTimeline = ShortcutBinding(keyCode: 9, modifiers: [.command, .shift], key: "V")
        let oldPlain = ShortcutBinding(keyCode: 9, modifiers: [.command, .control], key: "V")
        struct Legacy: Encodable {
            var timeline: ShortcutBinding?
            var stack: ShortcutBinding?
            var plainPaste: ShortcutBinding?
            var quickPaste: ShortcutBinding?
        }
        let old = Legacy(timeline: oldTimeline, stack: ShortcutAction.timeline.defaultBinding,
                         plainPaste: oldPlain, quickPaste: nil)
        let migrated = try JSONDecoder().decode(ShortcutConfiguration.self, from: JSONEncoder().encode(old))
        #expect(migrated == .defaults)
        var customized = old
        customized.timeline = ShortcutBinding(keyCode: 9, modifiers: [.option, .command], key: "V")
        let kept = try JSONDecoder().decode(ShortcutConfiguration.self, from: JSONEncoder().encode(customized))
        #expect(kept.timeline == customized.timeline)
        #expect(kept.quickPaste == nil)
        customized.timeline = nil
        let cleared = try JSONDecoder().decode(ShortcutConfiguration.self, from: JSONEncoder().encode(customized))
        #expect(cleared.timeline == nil)
        #expect(cleared.quickPaste == nil)
        let encoded = try JSONEncoder().encode(migrated)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(object["stack"] == nil)
        #expect(object["plainPaste"] == nil)
        #expect(object["schemaVersion"] as? Int == 2)
    }

    @Test func permissionPromptOnlyOnNewGrant() {
        var existing = PermissionGrantTracker(granted: true)
        let startupPrompt = existing.update(granted: true)
        #expect(!startupPrompt)
        var fresh = PermissionGrantTracker(granted: false)
        var results: [Bool] = []
        for granted in [false, true, true, false, true] {
            results.append(fresh.update(granted: granted))
        }
        #expect(results == [false, true, false, false, false])
    }
}
