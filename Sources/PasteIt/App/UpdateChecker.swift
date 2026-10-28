import Foundation
import Combine
import PasteItCore
import Sparkle

/// Sparkle-backed updater. Keep `shared` alive for the app lifetime so automatic checks run.
@MainActor
final class UpdateChecker: NSObject, ObservableObject, SPUUpdaterDelegate, @MainActor SPUStandardUserDriverDelegate {
    static let shared = UpdateChecker()

    private var updaterController: SPUStandardUpdaterController!
    private var promptState = AutomaticUpdatePromptState()
    private var observations = Set<AnyCancellable>()

    private override init() {
        super.init()
        guard AppBrand.updatesEnabled else { return }
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: self
        )
        observeUpdaterSettings()
    }

    /// Manual check from menu or Settings → About. Sparkle presents its own UI.
    func checkForUpdates(source: String = "menu") {
        guard canCheckForUpdates else { return }
        updaterController.checkForUpdates(nil)
    }

    var canCheckForUpdates: Bool {
        updaterController?.updater.canCheckForUpdates ?? false
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController?.updater.automaticallyChecksForUpdates ?? false }
        set { updaterController?.updater.automaticallyChecksForUpdates = newValue }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { updaterController?.updater.automaticallyDownloadsUpdates ?? false }
        set { updaterController?.updater.automaticallyDownloadsUpdates = newValue }
    }

    // MARK: - Immediate update reminders

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        // Take responsibility for bringing scheduled alerts to the front even
        // though this is a dockless app. No interaction or Paste Stack gating.
        false
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        // Critical updates can reach this callback without finishing the
        // background cycle first. Clear the pending handoff to avoid a loop.
        promptState.updatePresented()
        if !handleShowingUpdate {
            // Sparkle defers this callback until its alert can be brought into
            // focus. This reuses the existing session rather than checking again.
            updaterController.checkForUpdates(nil)
        }
    }

    func updater(
        _ updater: SPUUpdater,
        willInstallUpdateOnQuit item: SUAppcastItem,
        immediateInstallationBlock immediateInstallHandler: @escaping () -> Void
    ) -> Bool {
        promptState.updatePrepared()
        // Let Sparkle finish the automatic cycle and keep its installer alive.
        // Holding the installation block would stall all subsequent checks.
        return false
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: Error?
    ) {
        guard promptState.finishCycle(failed: error != nil) else { return }
        // Sparkle has cleared sessionInProgress before invoking this delegate.
        // Start synchronously: deferring would race its next scheduling probe.
        // Its installer is already prepared, so the standard UI offers restart
        // immediately, along with install-on-quit and skip-version choices.
        checkForUpdates(source: "auto")
    }

    // MARK: - Private

    private func observeUpdaterSettings() {
        let updater = updaterController.updater
        Publishers.Merge3(
            updater.publisher(for: \.canCheckForUpdates),
            updater.publisher(for: \.automaticallyChecksForUpdates),
            updater.publisher(for: \.automaticallyDownloadsUpdates)
        )
        .sink { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.objectWillChange.send()
            }
        }
        .store(in: &observations)
    }
}
