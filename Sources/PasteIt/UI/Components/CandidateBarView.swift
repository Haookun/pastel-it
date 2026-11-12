import AppKit
import SwiftUI
import PasteItCore

/// IME-style candidate bar: a compact vertical list of one page of clips
/// (at most 10 rows) shown next to the text caret. Paging, number-key
/// selection, activation and closing are owned by the host panel controller;
/// this view renders chrome only and registers no keyboard handling. The
/// candidate rows themselves are a real AppKit `NSTableView` (see
/// `CandidateTableView`), which also owns the hover preview popover.
struct CandidateBarView: View {
    let items: [ClipItem] // 当前页（最多10条），由控制器分页
    let selectedID: UUID?
    let blobStore: BlobStore
    let pageIndex: Int
    let pageCount: Int
    let onPreviousPage: () -> Void
    let onNextPage: () -> Void
    let onActivate: (ClipItem) -> Void
    let onClose: () -> Void
    var statusText: String? = nil
    var placementNotice: String? = nil
    var dismissPreviewRequest: UUID? = nil
    /// Native right-click menu actions. Optional so existing call sites (e.g.
    /// NativeUIReview previews) keep compiling unchanged.
    var onPaste: ((ClipItem) -> Void)? = nil
    var onPastePlainText: ((ClipItem) -> Void)? = nil
    var onCopyPlainText: ((ClipItem) -> Void)? = nil
    /// Lets the host panel suspend outside-click dismissal while the native
    /// context menu tracks.
    var onContextMenuVisibilityChange: ((Bool) -> Void)? = nil

    static let panelWidth: CGFloat = 420
    static let rowHeight: CGFloat = 36
    static let topBarHeight: CGFloat = 32
    static let pageSize = 10

    /// IME-style chrome: macOS input-method candidate windows use a small,
    /// lightly rounded corner rather than the timeline's large panel radius.
    private var panelShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            candidateList
            if let statusText, !statusText.isEmpty {
                Divider()
                Text(statusText)
                    .help(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
        .frame(idealWidth: Self.panelWidth, maxWidth: Self.panelWidth)
        .background(ClearHostingBackground())
        // Native IME look: a clearly light, opaque material in light mode
        // (dark-adaptive), a hairline border, and a soft drop shadow.
        .background(.regularMaterial, in: panelShape)
        .overlay {
            panelShape.strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        }
        .clipShape(panelShape)
        .shadow(color: .black.opacity(0.16), radius: 12, y: 4)
    }

    // MARK: - Top bar (minimal: paging + close)

    private var topBar: some View {
        HStack(spacing: 8) {
            if let placementNotice, !placementNotice.isEmpty {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .help(placementNotice)
                    .accessibilityLabel(placementNotice)
            }

            Spacer(minLength: 4)

            Text(L10n.tr("candidateBar.page", default: "%lld/%lld", pageIndex + 1, max(1, pageCount)))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)

            barIconButton(
                systemImage: "chevron.up",
                label: L10n.tr("candidateBar.previousPage", default: "Previous page"),
                isEnabled: pageIndex > 0,
                action: onPreviousPage
            )
            barIconButton(
                systemImage: "chevron.down",
                label: L10n.tr("candidateBar.nextPage", default: "Next page"),
                isEnabled: pageIndex + 1 < pageCount,
                action: onNextPage
            )
            barIconButton(
                systemImage: "xmark",
                label: L10n.tr("candidateBar.close", default: "Close"),
                isEnabled: true,
                action: onClose
            )
        }
        .padding(.horizontal, 8)
        .frame(height: Self.topBarHeight)
    }

    // MARK: - Candidate rows (native NSTableView)

    @ViewBuilder
    private var candidateList: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label(L10n.tr("candidateBar.empty", default: "No Recent Clips"), systemImage: "tray")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
        } else {
            // Height follows the row count so short pages leave no blank space;
            // the NSScrollView inside takes over when the host constrains the
            // panel (e.g. near a screen edge or on a small screen).
            CandidateTableView(
                items: items,
                selectedID: selectedID,
                blobStore: blobStore,
                pageIndex: pageIndex,
                dismissPreviewRequest: dismissPreviewRequest,
                onActivate: onActivate,
                onPaste: onPaste,
                onPastePlainText: onPastePlainText,
                onCopyPlainText: onCopyPlainText,
                onContextMenuVisibilityChange: onContextMenuVisibilityChange
            )
            .frame(maxWidth: Self.panelWidth)
            // Ideal height follows the row count so short pages leave no blank
            // space; the NSScrollView inside takes over when the host
            // constrains the panel (e.g. near a screen edge).
            .frame(idealHeight: CGFloat(items.count) * Self.rowHeight,
                   maxHeight: CGFloat(items.count) * Self.rowHeight)
        }
    }

    // MARK: - Bar controls

    private func barIconButton(
        systemImage: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .help(label)
        .accessibilityLabel(label)
    }
}

// MARK: - Hover preview

/// Floating detail shown while hovering a candidate. Images load through the
/// existing async thumbnail pipeline; files show their full paths; text clips
/// show the long plain-text preview (never raw HTML). Kept as a SwiftUI view so
/// it can be reused by the AppKit popover (`NSHostingController`) and by
/// validation paths.
struct CandidateHoverPreview: View {
    let item: ClipItem
    let blobStore: BlobStore

    @State private var loadedImage: NSImage?
    @State private var didAttemptLoad = false

    private let previewWidth: CGFloat = 300
    /// Images keep the roomy fixed canvas; text is capped so long clips scroll
    /// instead of stretching the popover; files size to their content below.
    private let contentMaxHeight: CGFloat = 220

    private var imagePath: String? { item.thumbnailRelativePath ?? item.blobRelativePath }

    var body: some View {
        Group {
            switch item.primaryType {
            case .image:
                imageContent
                    .frame(width: previewWidth, height: contentMaxHeight)
            case .file:
                fileContent
                    .frame(width: previewWidth, alignment: .topLeading)
                    .frame(maxHeight: contentMaxHeight, alignment: .topLeading)
            default:
                textContent
                    .frame(width: previewWidth)
                    .frame(maxHeight: contentMaxHeight, alignment: .topLeading)
            }
        }
    }

    private var imageContent: some View {
        ZStack {
            Color.clear.pasteItPreviewInsetGlass()

            if let loadedImage {
                Image(nsImage: loadedImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else if didAttemptLoad {
                ContentUnavailableView(
                    L10n.tr("candidateBar.noPreview", default: "No Preview"),
                    systemImage: "photo"
                )
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .task(id: item.id) {
            didAttemptLoad = false
            let image = await ClipVisualCache.shared.loadImage(
                at: imagePath,
                blobStore: blobStore,
                maxPixelSize: 640
            )
            guard !Task.isCancelled else { return }
            loadedImage = image
            didAttemptLoad = true
        }
    }

    private var fileContent: some View {
        let urls = item.storedFileURLs
        return Group {
            if urls.isEmpty {
                textContent
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.tr("candidateBar.fileCount", default: "%lld files", urls.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(urls.enumerated()), id: \.offset) { _, url in
                                Text(url.path)
                                    .font(.system(size: 11))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    // Short file lists stay compact; long ones scroll.
                    .frame(height: fileListHeight(urls))
                }
            }
        }
    }

    private func fileListHeight(_ urls: [URL]) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 11)
        let height = urls.reduce(CGFloat.zero) { total, url in
            let measured = (url.path as NSString).boundingRect(with: NSSize(width: previewWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font]).height
            return total + ceil(measured) + 4
        }
        return min(180, max(16, height))
    }

    private var textContent: some View {
        let text = item.previewText
        return Group {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(L10n.tr("candidateBar.emptyText", default: "Empty"))
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(text)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
