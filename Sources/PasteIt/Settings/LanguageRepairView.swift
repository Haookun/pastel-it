import AppKit
import SwiftUI
import PasteItCore

/// Settings UI for repairing missing interface language resources.
/// The heavy lifting (validation, download, import) lives in
/// `LanguageRepairController`; this view only reflects its state.
struct LanguageRepairView: View {
    @ObservedObject private var controller: LanguageRepairController

    init(controller: LanguageRepairController = .shared) {
        self._controller = ObservedObject(wrappedValue: controller)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                controller.needsRepair
                    ? L10n.tr("languageRepair.statusFallback", default: "Language resources are missing; running in English temporarily.")
                    : L10n.tr("languageRepair.statusOK", default: "Language Resources"),
                systemImage: controller.needsRepair ? "exclamationmark.triangle" : "checkmark.circle"
            )
            .foregroundStyle(controller.needsRepair ? Color.orange : Color.primary)

            if let message = controller.message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { repairButtons }
                VStack(alignment: .leading, spacing: 8) { repairButtons }
            }
        }
    }

    @ViewBuilder
    private var repairButtons: some View {
        Group {
                Button(L10n.tr("languageRepair.download", default: "Download and Repair")) {
                    Task { await controller.downloadAndInstall() }
                }
                .disabled(controller.isBusy)

                if controller.requiresBrowserLogin {
                    Button(L10n.tr("languageRepair.browser", default: "Download via GitHub Login")) {
                        controller.openGitHubDownload()
                    }
                    .disabled(controller.isBusy)
                }

                Button(L10n.tr("languageRepair.import", default: "Install Downloaded Language Pack…")) {
                    controller.chooseAndInstall()
                }
                .disabled(controller.isBusy)

                if controller.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
        }
    }
}

/// One-shot native alert shown when the app had to fall back to English
/// because the selected language's resources are missing.
@MainActor
enum LanguageRepairPrompt {
    private static var didPresent = false

    static func presentIfNeeded(controller: LanguageRepairController = .shared) {
        guard !didPresent, controller.needsRepair, !controller.isBusy else { return }
        didPresent = true

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.tr("languageRepair.missingTitle", default: "Language Resources Missing / 语言资源缺失")
        alert.informativeText = L10n.tr(
            "languageRepair.missingMessage",
            default: "The resources for your selected language are missing. The app will continue running in English. Your settings and history are not affected."
        )
        alert.addButton(withTitle: L10n.tr("languageRepair.download", default: "Download and Repair"))
        alert.addButton(withTitle: L10n.tr("languageRepair.importShort", default: "Install Downloaded Language Pack"))
        alert.addButton(withTitle: L10n.tr("languageRepair.later", default: "Later"))

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            controller.revealRepairSettings()
            Task { await controller.downloadAndInstall() }
        case .alertSecondButtonReturn:
            controller.revealRepairSettings()
            controller.chooseAndInstall()
        default:
            break // Later
        }
    }
}
