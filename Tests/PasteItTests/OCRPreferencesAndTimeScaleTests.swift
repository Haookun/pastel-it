import Foundation
import Testing
@testable import PasteItCore

struct OCRPreferencesAndTimeScaleTests {
    @Test func normalizesOCRParametersAndLanguages() throws {
        var value = OCRConfiguration()
        value.languages = ["ja-JP", "", "en-US", "ja-JP"]
        value.minimumTextHeight = .infinity
        #expect(value.normalized.languages == ["en-US", "ja-JP"])
        #expect(value.normalized.minimumTextHeight == 0)
        value.minimumTextHeight = 2
        #expect(value.normalized.minimumTextHeight == 0.1)
        value.minimumTextHeight = -1
        #expect(value.normalized.minimumTextHeight == 0)
        let decoded = try JSONDecoder().decode(OCRConfiguration.self, from: JSONEncoder().encode(value))
        #expect(decoded == value)
    }

    @Test func timeScaleNavigatesCopyTimeDespiteHistoryReordering() throws {
        let times: [TimeInterval] = [100, 0, 60]
        let entries = times.map { TimelineTimeScale.Entry(id: UUID(), date: Date(timeIntervalSince1970: $0)) }
        let scale = TimelineTimeScale(entries: entries)
        #expect(scale.fraction(for: entries[0].date) == 0)
        #expect(scale.fraction(for: entries[1].date) == 1)
        #expect(scale.nearest(to: -10)?.id == entries[0].id)
        #expect(scale.nearest(to: 20)?.id == entries[1].id)
        #expect(scale.nearest(to: 0.45)?.id == entries[2].id)
        #expect(scale.nearest(to: .nan)?.id == entries[0].id)
        #expect(scale.nearest(to: 0.7)?.id == entries[2].id)
    }

    @Test func timeScaleHandlesEmptyEqualAndSingleTimes() {
        #expect(TimelineTimeScale(entries: []).nearest(to: 0.5) == nil)
        let entries = [UUID(), UUID()].map { TimelineTimeScale.Entry(id: $0, date: .distantPast) }
        let scale = TimelineTimeScale(entries: entries)
        #expect(scale.fraction(for: .distantPast) == 0.5)
        #expect(scale.nearest(to: 0)?.date == .distantPast)
        let single = TimelineTimeScale(entries: [entries[0]])
        #expect(single.nearest(to: 1) == entries[0])
    }

    @Test func quickShortcutDefaultsConflictWithoutOverwritingTimeline() throws {
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(ShortcutConfiguration.defaults)) as? [String: Any])
        object.removeValue(forKey: "quickPaste")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(ShortcutConfiguration.self, from: legacy)
        #expect(decoded.quickPaste == nil)
        #expect(decoded.timeline?.keyCode == 9)
        var value = ShortcutConfiguration.defaults
        value.quickPaste = ShortcutAction.quickPaste.defaultBinding
        #expect(!value.isValid)
        value.timeline = ShortcutBinding(keyCode: 9, modifiers: [.command, .option], key: "V")
        #expect(value.isValid)
        #expect(value.quickPaste?.display == "⇧⌘V")
    }
}
