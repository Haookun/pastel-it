import SwiftUI
import PasteItCore

struct SettingsView: View {
    static let sidebarWidth: CGFloat = 223

    private enum Page: Hashable {
        case general, clipboard, ocr, quickPaste, folders, privacy, storage, about

        var title: String {
            switch self {
            case .general: L10n.tr("settings.tab.general", default: "General")
            case .clipboard: L10n.tr("settings.tab.clipboard", default: "Clipboard & History")
            case .ocr: L10n.tr("settings.tab.ocr", default: "OCR")
            case .quickPaste: L10n.tr("settings.tab.quickPaste", default: "Quick Paste")
            case .folders: L10n.tr("settings.tab.folders", default: "Folders")
            case .privacy: L10n.tr("settings.tab.privacy", default: "Privacy")
            case .storage: L10n.tr("settings.tab.storage", default: "Storage")
            case .about: L10n.tr("settings.tab.about", default: "About")
            }
        }

        var symbol: String {
            switch self {
            case .general: "gearshape.fill"
            case .clipboard: "clipboard.fill"
            case .ocr: "text.viewfinder"
            case .quickPaste: "bolt.fill"
            case .folders: "folder.fill"
            case .privacy: "hand.raised.fill"
            case .storage: "internaldrive.fill"
            case .about: "info"
            }
        }

        var sidebarTitle: String {
            switch self {
            case .clipboard:
                L10n.tr("settings.sidebar.clipboard", default: "Clipboard")
            default:
                title
            }
        }

        var tint: Color {
            switch self {
            case .general, .storage: .gray
            case .clipboard, .privacy, .about, .ocr, .quickPaste: .blue
            case .folders: .orange
            }
        }
    }

    @ObservedObject var appState: AppState
    @ObservedObject private var settings: AppSettings
    @ObservedObject private var historyStore: HistoryStore
    @ObservedObject private var updateChecker = UpdateChecker.shared
    /// Mirrors SMAppService registration; refreshed on appear and app activation
    /// so turning the login item off in System Settings is reflected here.
    @State private var launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
    @State private var pendingCleanup: PendingCleanup?
    @State private var selectedPage: Page? = .general
    @State private var accessibilityTrusted = SystemPasteSynthesizer.isAccessibilityTrusted

    private struct PendingCleanup: Identifiable {
        let id = UUID()
        let ids: Set<UUID>
        let keepSaved: Bool
        let retention: AppSettings.KeepHistory?
    }

    init(appState: AppState, showLanguageRepair: Bool = false) {
        _selectedPage = State(initialValue: showLanguageRepair ? .about : .general)
        self.appState = appState
        _settings = ObservedObject(wrappedValue: appState.settings)
        _historyStore = ObservedObject(wrappedValue: appState.historyStore)
    }

    var body: some View {
        // Plain HStack layout under a standard AppKit titlebar: a fixed-width
        // native sidebar List, a single Divider, and the detail Form. This
        // avoids NavigationSplitView's full-height sidebar toolbar chrome,
        // which misaligned the split divider between titlebar and content.
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailColumn
        }
        .toggleStyle(.switch)
        .frame(minWidth: 720, minHeight: 500)
        .onReceive(NotificationCenter.default.publisher(for: SettingsWindowController.languageRepairRequested)) { _ in
            selectedPage = .about
        }
        .onAppear {
            accessibilityTrusted = SystemPasteSynthesizer.isAccessibilityTrusted
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityTrusted = SystemPasteSynthesizer.isAccessibilityTrusted
        }
        .sheet(item: $pendingCleanup) { cleanup in
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.tr("removal.confirmTitle", default: "Review History Cleanup"))
                    .font(.headline)
                Text(L10n.tr("removal.confirmCount", default: "%lld clips will be permanently deleted. This cannot be undone and ends removal undo.", cleanup.ids.count))
                    .fixedSize(horizontal: false, vertical: true)
                Text(cleanup.keepSaved
                    ? L10n.tr("removal.keepSaved", default: "Pinned clips and clips in folders will be kept.")
                    : L10n.tr("removal.includeSaved", default: "This includes Pinned and every folder. The folders themselves will remain."))
                    .foregroundStyle(.secondary)
                if let retention = cleanup.retention {
                    Text(L10n.tr("removal.newRetention", default: "New retention period: %@", retention.title))
                }
                HStack {
                    Spacer()
                    Button(L10n.tr("common.cancel", default: "Cancel"), role: .cancel) { pendingCleanup = nil }
                        .keyboardShortcut(.cancelAction)
                    Button(L10n.tr("removal.confirmDelete", default: "Delete Reviewed Clips"), role: .destructive) {
                        if historyStore.deleteReviewedClips(ids: cleanup.ids, keepSaved: cleanup.keepSaved),
                           let retention = cleanup.retention {
                            settings.keepHistory = retention
                        }
                        pendingCleanup = nil
                    }
                }
            }
            .padding(24)
            .frame(width: 440)
        }
        .alert(L10n.tr("removal.failedTitle", default: "History Was Not Changed"), isPresented: Binding(
            get: { historyStore.removalError != nil },
            set: { if !$0 { historyStore.removalError = nil } }
        )) {
            Button(L10n.tr("action.dismiss", default: "Dismiss message")) { historyStore.removalError = nil }
        } message: {
            Text(historyStore.removalError ?? "")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedPage) {
            Section(L10n.tr("settings.group.app", default: "App")) {
                sidebarRow(.general)
                sidebarRow(.clipboard)
                sidebarRow(.ocr)
                sidebarRow(.quickPaste)
            }
            Section(L10n.tr("settings.group.data", default: "Data")) {
                sidebarRow(.folders)
                sidebarRow(.privacy)
                sidebarRow(.storage)
            }
            Section {
                sidebarRow(.about)
            }
        }
        .listStyle(.sidebar)
        .frame(width: Self.sidebarWidth)
        .frame(maxHeight: .infinity)
    }

    private func sidebarRow(_ page: Page) -> some View {
        Label {
            Text(page.sidebarTitle)
        } icon: {
            if selectedPage == page {
                Image(systemName: page.symbol)
            } else {
                Image(systemName: page.symbol)
                    .foregroundStyle(page.tint)
            }
        }
        .tag(page)
    }

    // MARK: - Detail

    private var detailColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text((selectedPage ?? .general).title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)
            detail
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var detail: some View {
        switch selectedPage ?? .general {
        case .general: general
        case .clipboard: clipboard
        case .ocr: OCRSettingsView(settings: settings)
        case .quickPaste: QuickPasteSettingsView(settings: settings, manager: AppRuntime.shared.hotkeyManager)
        case .folders: FoldersSettingsView(historyStore: historyStore)
        case .privacy: PrivacySettingsView(settings: settings)
        case .storage: storage
        case .about: about
        }
    }

    private var versionLabel: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return L10n.tr("settings.version", default: "Pastel it！ %@ (%@)", short, build)
    }

    private var about: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 56, height: 56)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pastel it！")
                            .font(.title2.bold())
                        Text(versionLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                Text(L10n.tr("settings.aboutBlurb", default: "Pastel it！ is a local-first clipboard manager. History stays on this Mac."))
                    .foregroundStyle(.secondary)
            }

            Section { LanguageRepairView() }

            Section(L10n.tr("settings.group.help", default: "Help")) {
                Button(L10n.tr("settings.showTutorial", default: "Show Tutorial…")) {
                    OnboardingWindowController.shared.show(
                        settings: settings,
                        flow: .install,
                        source: "settings"
                    )
                }
                Button(L10n.tr("settings.whatsNew", default: "What's New…")) {
                    OnboardingWindowController.shared.show(
                        settings: settings,
                        flow: .update,
                        source: "settings"
                    )
                }
            }

            if AppBrand.updatesEnabled {
                Section(L10n.tr("settings.group.updates", default: "Updates")) {
                    Toggle(
                        L10n.tr("settings.automaticallyCheckUpdates", default: "Automatically check for updates"),
                        isOn: $updateChecker.automaticallyChecksForUpdates
                    )
                    Toggle(
                        L10n.tr("settings.automaticallyDownloadUpdates", default: "Automatically download updates"),
                        isOn: $updateChecker.automaticallyDownloadsUpdates
                    )
                    .disabled(!updateChecker.automaticallyChecksForUpdates)
                    Text(L10n.tr(
                        "settings.automaticUpdatesHelp",
                        default: "Updates download in the background. When an update is ready, you’ll be asked to restart Pastel it！. You can also install when you quit."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button(L10n.tr("menu.checkUpdates", default: "Check for Updates…")) {
                        updateChecker.checkForUpdates(source: "settings")
                    }
                    .disabled(!updateChecker.canCheckForUpdates)
                }
            } else {
                Section(L10n.tr("settings.group.updates", default: "Updates")) {
                    Text(L10n.tr("settings.privateUpdates", default: "Automatic updates are not configured for this private derivative. Get builds from your own repository."))
                        .foregroundStyle(.secondary)
                    Link("GitHub", destination: AppBrand.repositoryURL)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var general: some View {
        Form {
            Section(L10n.tr("settings.group.startup", default: "Startup")) {
                Toggle(L10n.tr("settings.launchAtLogin", default: "Launch at login"), isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { enabled in
                        LaunchAtLoginManager.setEnabled(enabled)
                        settings.launchAtLogin = enabled
                        // Read back: registration can stay pending (.requiresApproval)
                        // when the user previously disabled it in System Settings.
                        launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
                    }
                ))
                .disabled(!LaunchAtLoginManager.supportsLaunchAtLogin)
                .onAppear {
                    launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
                ) { _ in
                    launchAtLoginEnabled = LaunchAtLoginManager.isEnabled
                }
            }

            Section {
                Picker(L10n.tr("action.setting", default: "Timeline primary action"), selection: Binding(
                    get: { settings.timelinePrimaryAction },
                    set: { settings.timelinePrimaryAction = $0 }
                )) {
                    ForEach(TimelinePrimaryAction.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }
                if settings.timelinePrimaryAction == .paste && !accessibilityTrusted {
                    DirectPastePermissionView()
                }
            } header: {
                Text(L10n.tr("settings.group.pasting", default: "Pasting"))
            } footer: {
                Text(L10n.tr("action.settingDetail", default: "Double-click, Return, and ⌘1–9 use the selected action. Direct Paste is the default."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                ShortcutSettingsView(manager: AppRuntime.shared.hotkeyManager, actions: [.timeline])
            } header: {
                Text(L10n.tr("settings.group.shortcuts", default: "Keyboard Shortcuts"))
            } footer: {
                Text(L10n.tr("shortcuts.timelineFootnote", default: "Open clipboard history with ⇧⌘C. Configure Quick Paste separately on the Quick Paste page."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var clipboard: some View {
        Form {
            Section(L10n.tr("settings.group.displayStyle", default: "Display Style")) {
                Picker(L10n.tr("clipboard.style.picker", default: "Presentation"), selection: $settings.clipboardPresentationStyle) {
                    Text(L10n.tr("clipboard.style.timeline", default: "Timeline"))
                        .tag(ClipboardPresentationStyle.timeline)
                    Text(L10n.tr("clipboard.style.candidateBar", default: "Candidate Bar"))
                        .tag(ClipboardPresentationStyle.candidateBar)
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                ClipboardStylePreview(style: settings.clipboardPresentationStyle)

                if settings.clipboardPresentationStyle == .candidateBar {
                    CandidatePlacementPermissionRow(trusted: accessibilityTrusted)
                    Text(L10n.tr("candidatePlacement.help", default: "Accessibility lets Pastel it！ place the candidate bar next to your text cursor. Without it, the bar appears near the mouse pointer instead."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(L10n.tr("clipboard.style.help", default: "Choose a timeline or a compact bar of recent clips. Open either with your clipboard shortcut."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.tr("settings.group.capture", default: "Capture")) {
                Toggle(L10n.tr("settings.pauseCapture", default: "Pause clipboard capture"), isOn: $settings.capturePaused)
            }

            Section {
                Picker(L10n.tr("settings.keepHistory", default: "Keep history"), selection: Binding(
                    get: { settings.keepHistory },
                    set: { retention in
                        let ids = Set(historyStore.retentionCandidates(retention).map(\.id))
                        if ids.isEmpty { settings.keepHistory = retention }
                        else { pendingCleanup = PendingCleanup(ids: ids, keepSaved: true, retention: retention) }
                    }
                )) {
                    ForEach(AppSettings.KeepHistory.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                LabeledContent(L10n.tr("settings.maxHistoryItems", default: "Max history items")) {
                    HStack(spacing: 6) {
                        TextField(
                            "",
                            value: $settings.maxHistoryItems,
                            format: .number
                        )
                        .labelsHidden()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 72)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settings.maxHistoryItems) { _, newValue in
                            settings.maxHistoryItems = min(50_000, max(100, newValue))
                        }

                        Stepper(
                            "",
                            value: $settings.maxHistoryItems,
                            in: 100...50_000,
                            step: 100
                        )
                        .labelsHidden()
                    }
                }
            } header: {
                Text(L10n.tr("settings.group.history", default: "History"))
            } footer: {
                Text(L10n.tr("removal.keepSaved", default: "Pinned clips and clips in folders will be kept."))
            }

            Section {
                DisclosureGroup(L10n.tr("settings.group.advanced", default: "Advanced")) {
                    LabeledContent(L10n.tr("settings.clipboardPolling", default: "Clipboard polling")) {
                        HStack(spacing: 6) {
                            TextField(
                                "",
                                value: Binding(
                                    get: { settings.clipboardCheckInterval },
                                    set: {
                                        settings.clipboardCheckInterval = min(
                                            2.0,
                                            max(0.2, ($0 * 20).rounded() / 20)
                                        )
                                    }
                                ),
                                format: .number.precision(.fractionLength(2))
                            )
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)
                            .textFieldStyle(.roundedBorder)

                            Text(L10n.tr("settings.seconds", default: "s"))
                                .foregroundStyle(.secondary)

                            Stepper(
                                "",
                                value: $settings.clipboardCheckInterval,
                                in: 0.2...2.0,
                                step: 0.05
                            )
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var storage: some View {
        Form {
            Section(L10n.tr("settings.tab.storage", default: "Storage")) {
                Stepper(
                    L10n.tr("settings.maxBinaryStorage", default: "Max binary storage: %lld MB", settings.maxBlobMegabytes),
                    value: $settings.maxBlobMegabytes,
                    in: 128...20_480,
                    step: 128
                )

                Button(L10n.tr("settings.pruneNow", default: "Prune Now")) {
                    pendingCleanup = PendingCleanup(ids: Set(historyStore.pruneCandidates().map(\.id)), keepSaved: true, retention: nil)
                }
            }

            Section(L10n.tr("settings.group.cleanup", default: "History Cleanup")) {
                Button(L10n.tr("removal.clearKeepSaved", default: "Clear History, Keep Pinned & Folders…"), role: .destructive) {
                    pendingCleanup = PendingCleanup(ids: Set(historyStore.clearHistoryCandidates(keepSaved: true).map(\.id)), keepSaved: true, retention: nil)
                }

                Button(L10n.tr("settings.clearAllHistory", default: "Clear All History"), role: .destructive) {
                    pendingCleanup = PendingCleanup(ids: Set(historyStore.clips.map(\.id)), keepSaved: false, retention: nil)
                }
            }
        }
        .formStyle(.grouped)
    }
}
