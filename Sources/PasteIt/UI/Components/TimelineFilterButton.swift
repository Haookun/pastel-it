import SwiftUI
import PasteItCore

/// Native menu selection and checkmarks, with asynchronously computed counts.
struct TimelineFilterButton: View {
    @ObservedObject var appState: AppState
    @State private var filterCounts: [FilterCategory: Int]?
    @State private var countsTask: Task<Void, Never>?
    private var isActive: Bool { appState.selectedFilter != .all }

    var body: some View {
        HStack(spacing: 4) {
            Menu {
                Picker(L10n.tr("filter.byType", default: "Filter by type"), selection: Binding(
                    get: { appState.selectedFilter },
                    set: { appState.dismissPreview(); appState.setFilter($0) }
                )) {
                    ForEach(FilterCategory.menuItems) { category in
                        Label("\(category.title) · \(filterCounts?[category].map(String.init) ?? "—")",
                              systemImage: category.systemImage)
                            .tag(category)
                    }
                }
            } label: {
                if isActive {
                    Label("\(appState.selectedFilter.title) · \(appState.visibleClips.count)",
                          systemImage: appState.selectedFilter.systemImage)
                        .monospacedDigit()
                } else {
                    Label(L10n.tr("filter.byType", default: "Filter by type"), systemImage: "line.3.horizontal.decrease.circle")
                        .labelStyle(.iconOnly)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help(L10n.tr("filter.byType", default: "Filter by type"))
            if isActive {
                Button {
                    appState.setFilter(.all)
                } label: {
                    Label(L10n.tr("filter.clear", default: "Clear type filter"), systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help(L10n.tr("filter.clear", default: "Clear type filter"))
            }
        }
        .controlSize(.regular)
        .onAppear { scheduleFilterCounts() }
        .onReceive(appState.historyStore.changes) { _ in scheduleFilterCounts() }
        .onChange(of: appState.searchHighlight) { _, _ in scheduleFilterCounts() }
        .onChange(of: appState.selectedTab) { _, _ in scheduleFilterCounts() }
        .onDisappear { countsTask?.cancel(); countsTask = nil }
    }

    private func scheduleFilterCounts() {
        countsTask?.cancel()
        countsTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            let counts = await appState.countsMatchingAllFilters()
            guard !Task.isCancelled else { return }
            filterCounts = counts
        }
    }
}
