import AppKit
import SwiftUI
import UniformTypeIdentifiers
import PasteItCore

struct PrivacySettingsView: View {
    @ObservedObject var settings: AppSettings

    @State private var installedApps: [InstalledApp] = []
    @State private var selectedBundleIDs: Set<String> = []
    @State private var isLoadingApps = false
    @State private var isShowingAddSheet = false
    @State private var logSummary: DiagnosticLogSummary?
    @State private var logStatus: String?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        Form {
            Section(L10n.tr("settings.group.permissions", default: "System Permissions")) {
                DirectPastePermissionView()
            }

            Section {
                Text(L10n.tr("privacy.logs.description", default: "No usage information is collected or uploaded. Diagnostic logs are stored only on this Mac and never contain clipboard contents."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.tr("privacy.logs.retention", default: "Logs are kept for at most 14 days, up to about 768 KB."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(logSummaryText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L10n.tr("privacy.logs.delete", default: "Delete Past Logs"), role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                    .accessibilityIdentifier("privacy.deletePastLogs")
                }

                if let logStatus {
                    Text(logStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(L10n.tr("privacy.logs.title", default: "Local Diagnostic Logs"))
            } footer: {
                Text(L10n.tr("privacy.logs.footerScope", default: "Deleting only removes this app's local log files. It never touches settings, clipboard history, attachments, or macOS system logs."))
            }

            Section {
                if ignoredApps.isEmpty {
                    Text(L10n.tr("privacy.noIgnoredApps", default: "No ignored apps"))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    List(selection: $selectedBundleIDs) {
                        ForEach(ignoredApps) { app in
                            HStack(spacing: 10) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(app.name)
                                    Text(app.bundleIdentifier)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                            .tag(app.bundleIdentifier)
                        }
                    }
                    .frame(minHeight: 140, maxHeight: 220)
                    .listStyle(.plain)
                }

                HStack(spacing: 0) {
                    Button {
                        isShowingAddSheet = true
                        loadAppsIfNeeded()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 28, height: 22)
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.tr("privacy.addApp", default: "Add App"))

                    Divider()
                        .frame(height: 16)

                    Button {
                        removeSelectedApps()
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 28, height: 22)
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedBundleIDs.isEmpty)
                    .help(L10n.tr("privacy.removeApp", default: "Remove App"))

                    Spacer()
                }
                .padding(.top, 2)
            } header: {
                Text(L10n.tr("privacy.ignoredApps", default: "Ignored Apps"))
            } footer: {
                Text(L10n.tr("privacy.ignoredAppsFooter", default: "Copies made in these apps are never saved to history. Use this for password managers and other sensitive apps."))
            }

            Section {
                Text(L10n.tr("privacy.protectedBlurb", default: "Sensitive clipboard markers from apps — such as password fields and temporary clips — are ignored automatically."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(L10n.tr("privacy.protectedContent", default: "Protected Content"))
            } footer: {
                Text(L10n.tr("privacy.protectedFooter", default: "Ignored Apps skip everything from a whole app. Protected Content skips only marked sensitive pasteboard data, from any app."))
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $isShowingAddSheet) {
            AddIgnoredAppSheet(
                installedApps: installedApps,
                isLoading: isLoadingApps,
                alreadyIgnored: settings.ignoredBundleIdentifiers,
                onAdd: { app in
                    var next = settings.ignoredBundleIdentifiers
                    next.insert(app.bundleIdentifier)
                    settings.ignoredBundleIdentifiers = next
                    isShowingAddSheet = false
                },
                onCancel: { isShowingAddSheet = false },
                onChooseFromDisk: { presentOpenPanel() }
            )
            .frame(width: 420, height: 480)
        }
        .alert(
            L10n.tr("privacy.logs.confirmTitle", default: "Delete Past Logs?"),
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button(L10n.tr("common.cancel", default: "Cancel"), role: .cancel) {}
            Button(L10n.tr("privacy.logs.delete", default: "Delete Past Logs"), role: .destructive) {
                deletePastLogs()
            }
        } message: {
            Text(L10n.tr("privacy.logs.confirmMessage", default: "This permanently deletes this app's past local diagnostic log files. Settings, clipboard history, and attachments are not affected."))
        }
        .onAppear {
            loadAppsIfNeeded()
            refreshLogSummary()
        }
    }

    private var logSummaryText: String {
        let summary = logSummary ?? DiagnosticLogSummary(fileCount: 0, totalBytes: 0)
        let size = ByteCountFormatter.string(fromByteCount: summary.totalBytes, countStyle: .file)
        return L10n.tr("privacy.logs.summary", default: "%lld files · %@", Int64(summary.fileCount), size)
    }

    @MainActor
    private func refreshLogSummary() {
        do {
            logSummary = try DiagnosticLogs.shared.store.snapshot()
        } catch {
            logSummary = nil
            logStatus = L10n.tr("privacy.logs.failed", default: "Something went wrong. Please try again later.")
        }
    }

    @MainActor
    private func deletePastLogs() {
        do {
            let deleted = try DiagnosticLogs.shared.store.clearPastLogs()
            logStatus = L10n.tr("privacy.logs.deleted", default: "Deleted %lld past log files.", Int64(deleted))
        } catch {
            logStatus = L10n.tr("privacy.logs.failed", default: "Something went wrong. Please try again later.")
        }
        refreshLogSummary()
    }

    private var ignoredApps: [InstalledApp] {
        let byID = Dictionary(uniqueKeysWithValues: installedApps.map { ($0.bundleIdentifier, $0) })
        return settings.ignoredBundleIdentifiers.sorted().map { bundleID in
            if let app = byID[bundleID] {
                return app
            }
            return InstalledApp.placeholder(bundleIdentifier: bundleID)
        }
    }

    private func removeSelectedApps() {
        var next = settings.ignoredBundleIdentifiers
        next.subtract(selectedBundleIDs)
        settings.ignoredBundleIdentifiers = next
        selectedBundleIDs.removeAll()
    }

    private func loadAppsIfNeeded() {
        guard installedApps.isEmpty else { return }
        isLoadingApps = true
        Task.detached(priority: .userInitiated) {
            let apps = InstalledAppCatalog.load()
            await MainActor.run {
                installedApps = apps
                isLoadingApps = false
            }
        }
    }

    private func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = L10n.tr("privacy.chooseAppPanel", default: "Choose an app to ignore")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier,
              !bundleID.isEmpty
        else { return }

        var next = settings.ignoredBundleIdentifiers
        next.insert(bundleID)
        settings.ignoredBundleIdentifiers = next
        isShowingAddSheet = false

        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        if !installedApps.contains(where: { $0.bundleIdentifier == bundleID }) {
            installedApps.append(
                InstalledApp(
                    bundleIdentifier: bundleID,
                    name: name,
                    icon: icon,
                    path: url.path
                )
            )
            installedApps.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }
}

private struct AddIgnoredAppSheet: View {
    let installedApps: [InstalledApp]
    let isLoading: Bool
    let alreadyIgnored: Set<String>
    let onAdd: (InstalledApp) -> Void
    let onCancel: () -> Void
    let onChooseFromDisk: () -> Void

    @State private var searchText = ""

    private var candidates: [InstalledApp] {
        let available = installedApps.filter { !alreadyIgnored.contains($0.bundleIdentifier) }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return available }
        return available.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.tr("privacy.addIgnoredApp", default: "Add Ignored App"))
                    .font(.headline)
                Spacer()
                Button(L10n.tr("privacy.chooseApp", default: "Choose…")) { onChooseFromDisk() }
            }
            .padding()

            TextField(L10n.tr("privacy.search", default: "Search"), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if isLoading && installedApps.isEmpty {
                ProgressView(L10n.tr("privacy.loadingApps", default: "Loading apps…"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(candidates) { app in
                    Button {
                        onAdd(app)
                    } label: {
                        HStack(spacing: 10) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.name)
                                    .foregroundStyle(.primary)
                                Text(app.bundleIdentifier)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Spacer()
                Button(L10n.tr("common.cancel", default: "Cancel"), action: onCancel)
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
    }
}
