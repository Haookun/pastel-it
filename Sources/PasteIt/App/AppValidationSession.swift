import Foundation

/// Explicit opt-in for local interaction checks using the real application UI.
/// The regular launch path continues to use the existing persistent history.
@MainActor
final class AppValidationSession {
    let defaultsDomain = "PastelIt-Validation-\(UUID().uuidString)"
    let defaults: UserDefaults
    let settings: AppSettings
    let historyStore: HistoryStore

    init() {
        defaults = UserDefaults(suiteName: defaultsDomain)!
        settings = AppSettings(defaults: defaults)
        settings.launchAtLogin = false
        settings.agentAPIEnabled = false
        settings.hasCompletedOnboarding = true
        settings.seenWhatsNewContentVersion = AppSettings.currentWhatsNewContentVersion
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PasteItEphemeral-Validation-\(UUID().uuidString)")
        historyStore = HistoryStore(ephemeralBlobRoot: root, settings: settings)
        for index in 0..<48 {
            historyStore.context.insert(ClipItem(
                createdAt: Date().addingTimeInterval(Double(-index * 3600)),
                title: "Validation note \(index)",
                plainText: "Synthetic note \(index) · 合成记录 · テスト",
                primaryType: .text, pasteboardTypes: ["public.utf8-plain-text"],
                sourceAppName: "Pastel it validation", contentHash: "validation-note-\(index)"
            ))
        }
        try? historyStore.context.save()
        historyStore.refresh()
    }

    func tearDown() {
        historyStore.destroyEphemeralFiles()
        defaults.removePersistentDomain(forName: defaultsDomain)
    }
}
