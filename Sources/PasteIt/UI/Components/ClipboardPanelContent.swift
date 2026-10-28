import SwiftUI
import PasteItCore

/// Both presentations share one AppKit panel and the existing pasteboard writer.
struct ClipboardPanelContent: View {
    @ObservedObject var appState: AppState
    let pasteController: PasteController
    @ObservedObject var controller: TimelinePanelController
    @ObservedObject private var settings: AppSettings
    @ObservedObject private var historyStore: HistoryStore

    init(appState: AppState, pasteController: PasteController, controller: TimelinePanelController) {
        self.appState = appState
        self.pasteController = pasteController
        self.controller = controller
        _settings = ObservedObject(wrappedValue: appState.settings)
        _historyStore = ObservedObject(wrappedValue: appState.historyStore)
    }

    var body: some View {
        if settings.clipboardPresentationStyle == .timeline {
            TimelineView(appState: appState, pasteController: pasteController)
        } else {
            CandidateBarView(items: controller.candidatePageItems, selectedID: controller.candidateSelectedID,
                             blobStore: historyStore.blobStore,
                             pageIndex: controller.candidatePageIndex, pageCount: controller.candidatePageCount,
                             onPreviousPage: controller.previousCandidatePage,
                             onNextPage: controller.nextCandidatePage,
                             onActivate: controller.activateCandidate,
                             onClose: { controller.hide() },
                             statusText: controller.candidateMessage,
                             placementNotice: controller.candidatePlacementNotice,
                             dismissPreviewRequest: controller.candidatePreviewDismissRequest)
        }
    }
}
