import AppKit
import SwiftUI
import PasteItCore

/// Shared label/numbering logic for candidate rows. History/OCR interpretation
/// stays in `ClipItem`; these helpers only pick which pre-computed string a row
/// should display.
enum CandidateRowContent {
    /// Keys 1–9 select rows 1–9; 0 selects the tenth row.
    static func keyLabel(for index: Int) -> String {
        index == 9 ? "0" : "\(index + 1)"
    }

    static func labelText(for item: ClipItem) -> String {
        // Resolve the full display text exactly as before (OCR / file name /
        // preview with empty-value fallbacks), then collapse to a single line
        // for the fixed-height row. Core appends "…" when content is dropped.
        let fullText: String
        switch item.primaryType {
        case .image:
            let ocr = item.ocrText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            fullText = ocr.isEmpty ? L10n.tr("clipType.image", default: "Image") : ocr
        case .file:
            guard let first = item.storedFileURLs.first else {
                fullText = L10n.tr("clipType.file", default: "File")
                break
            }
            fullText = first.lastPathComponent
        default:
            let text = item.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
            fullText = text.isEmpty ? item.primaryType.title : text
        }
        return CandidateRowSummary.firstLine(fullText)
    }

    static func extraFileCount(for item: ClipItem) -> Int {
        guard item.primaryType == .file else { return 0 }
        return max(0, item.storedFileURLs.count - 1)
    }
}

/// AppKit candidate list: an `NSScrollView` + headerless `NSTableView` wrapped
/// for SwiftUI. The table owns rendering, native selection color, hover
/// tracking and the floating `NSPopover` preview; all key handling stays with
/// the host panel controller. A single click activates a row via `onActivate`.
struct CandidateTableView: NSViewRepresentable {
    let items: [ClipItem]
    let selectedID: UUID?
    let blobStore: BlobStore
    /// Any page change invalidates hover context and closes the preview popover.
    let pageIndex: Int
    let dismissPreviewRequest: UUID?
    let onActivate: (ClipItem) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onActivate: onActivate, blobStore: blobStore)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.hasHorizontalScroller = false
        scrollView.verticalScrollElasticity = .allowed
        scrollView.horizontalScrollElasticity = .none

        let tableView = CandidateNativeTableView()
        tableView.headerView = nil
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.autoresizingMask = [.width]
        tableView.rowHeight = CandidateBarView.rowHeight
        tableView.intercellSpacing = .zero
        tableView.selectionHighlightStyle = .regular
        tableView.backgroundColor = .clear
        tableView.style = .plain
        tableView.usesAutomaticRowHeights = false
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.refusesFirstResponder = false
        tableView.setAccessibilityLabel(L10n.tr("candidateBar.list", default: "Clipboard candidates"))

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("candidate"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.target = context.coordinator
        tableView.action = #selector(Coordinator.handleClick(_:))

        context.coordinator.attach(tableView: tableView)
        scrollView.documentView = tableView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.onActivate = onActivate
        context.coordinator.blobStore = blobStore
        context.coordinator.update(items: items, selectedID: selectedID, pageIndex: pageIndex, dismissPreviewRequest: dismissPreviewRequest)
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var onActivate: (ClipItem) -> Void
        var blobStore: BlobStore

        private weak var tableView: NSTableView?
        private var items: [ClipItem] = []
        private var itemIDs: [UUID] = []
        private var rowSignatures: [String] = []
        private var pageIndex: Int = -1
        private var dismissPreviewRequest: UUID?

        private var popover: NSPopover?
        private var popoverItemID: UUID?
        private var popoverHovered = false
        private var hoveredRow: Int = -1
        private var hideWorkItem: DispatchWorkItem?

        init(onActivate: @escaping (ClipItem) -> Void, blobStore: BlobStore) {
            self.onActivate = onActivate
            self.blobStore = blobStore
        }

        func attach(tableView: NSTableView) {
            self.tableView = tableView
            let tracking = NSTrackingArea(
                rect: tableView.bounds,
                options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                owner: self,
                userInfo: ["region": "table"]
            )
            tableView.addTrackingArea(tracking)
        }

        // MARK: Content updates

        func update(items: [ClipItem], selectedID: UUID?, pageIndex: Int, dismissPreviewRequest: UUID?) {
            guard let tableView else { return }

            if self.dismissPreviewRequest != dismissPreviewRequest {
                closePopover()
                hoveredRow = -1
                self.dismissPreviewRequest = dismissPreviewRequest
            }
            let newIDs = items.map(\.id)
            let signatures = items.map { "\($0.primaryType.systemImage)|\(CandidateRowContent.labelText(for: $0))|\(CandidateRowContent.extraFileCount(for: $0))" }
            if pageIndex != self.pageIndex {
                // Paging invalidates hover context; close any lingering preview.
                closePopover()
                hoveredRow = -1
                self.pageIndex = pageIndex
            }
            if newIDs != itemIDs || signatures != rowSignatures {
                // Entries changed: any preview of a stale item must go away.
                if let popoverItemID, !newIDs.contains(popoverItemID) {
                    closePopover()
                }
                self.items = items
                self.itemIDs = newIDs
                self.rowSignatures = signatures
                tableView.reloadData()
            } else {
                self.items = items
            }

            if let selectedID, let row = itemIDs.firstIndex(of: selectedID) {
                if tableView.selectedRow != row {
                    tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                }
                tableView.scrollRowToVisible(row)
            } else if selectedID == nil, tableView.selectedRow != -1 {
                tableView.deselectAll(nil)
            }
        }

        func teardown() {
            cancelScheduledHide()
            closePopover()
            tableView?.dataSource = nil
            tableView?.delegate = nil
            tableView?.target = nil
            tableView = nil
        }

        // MARK: Data source / delegate

        func numberOfRows(in tableView: NSTableView) -> Int {
            items.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let identifier = NSUserInterfaceItemIdentifier("CandidateCell")
            let cell = (tableView.makeView(withIdentifier: identifier, owner: nil) as? CandidateCellView)
                ?? CandidateCellView(identifier: identifier)
            let item = items[row]
            cell.configure(
                keyLabel: CandidateRowContent.keyLabel(for: row),
                systemImage: item.primaryType.systemImage,
                labelText: CandidateRowContent.labelText(for: item),
                extraFileCount: CandidateRowContent.extraFileCount(for: item)
            )
            return cell
        }

        @objc func handleClick(_ sender: NSTableView) {
            let row = sender.clickedRow
            guard items.indices.contains(row) else { return }
            onActivate(items[row])
        }

        // MARK: Hover tracking + preview popover

        // NSTrackingArea delivers these to the owner object directly; the
        // coordinator is an NSObject (not NSResponder), so no `override`.
        @objc(mouseMoved:) func mouseMoved(with event: NSEvent) {
            guard let tableView else { return }
            let point = tableView.convert(event.locationInWindow, from: nil)
            let row = tableView.row(at: point)
            guard row != hoveredRow else { return }
            hoveredRow = row
            if row >= 0, items.indices.contains(row) {
                cancelScheduledHide()
                showPopover(for: row)
            } else {
                scheduleHide()
            }
        }

        @objc(mouseEntered:) func mouseEntered(with event: NSEvent) {
            let region = (event.trackingArea?.userInfo?["region"] as? String) ?? ""
            if region == "popover" {
                popoverHovered = true
                cancelScheduledHide()
            } else {
                cancelScheduledHide()
            }
        }

        @objc(mouseExited:) func mouseExited(with event: NSEvent) {
            let region = (event.trackingArea?.userInfo?["region"] as? String) ?? ""
            if region == "popover" {
                popoverHovered = false
                scheduleHide()
            } else {
                hoveredRow = -1
                scheduleHide()
            }
        }

        private func showPopover(for row: Int) {
            guard let tableView, items.indices.contains(row) else { return }
            let item = items[row]

            if popover == nil {
                let popover = NSPopover()
                popover.behavior = .semitransient
                popover.animates = true
                self.popover = popover
            }
            popoverItemID = item.id

            let host = NSHostingController(rootView:
                CandidateHoverPreview(item: item, blobStore: blobStore)
                    .padding(10)
                    .pasteItPopoverChrome()
            )
            popover?.contentViewController = host

            let rowRect = tableView.rect(ofRow: row)
            popover?.show(relativeTo: rowRect, of: tableView, preferredEdge: .maxX)

            // Let the pointer travel into the popover without dismissing it.
            let contentView = host.view
            contentView.trackingAreas.forEach { contentView.removeTrackingArea($0) }
            let tracking = NSTrackingArea(
                rect: contentView.bounds,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: ["region": "popover"]
            )
            contentView.addTrackingArea(tracking)
        }

        private func closePopover() {
            cancelScheduledHide()
            popoverHovered = false
            popoverItemID = nil
            popover?.performClose(nil)
            popover = nil
        }

        private func scheduleHide() {
            cancelScheduledHide()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                if self.hoveredRow < 0 && !self.popoverHovered {
                    self.closePopover()
                }
            }
            hideWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
        }

        private func cancelScheduledHide() {
            hideWorkItem?.cancel()
            hideWorkItem = nil
        }
    }
}

// MARK: - Cell view

/// One candidate row: 1–9/0 key chip, type icon, single-line summary and an
/// optional "+N more" chip. Colors follow `backgroundStyle` so text and icons
/// stay legible on the system selection highlight.
private final class CandidateCellView: NSTableCellView {
    private let keyChipBacking = NSView()
    private let keyField = NSTextField(labelWithString: "")
    private let iconView = NSImageView()
    private let titleField = NSTextField(labelWithString: "")
    private let countChipBacking = NSView()
    private let countField = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    convenience init(identifier: NSUserInterfaceItemIdentifier) {
        self.init(frame: .zero)
        self.identifier = identifier
    }

    private func setUp() {
        keyField.font = .monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
        keyField.alignment = .center
        keyField.lineBreakMode = .byClipping
        keyChipBacking.wantsLayer = true
        keyChipBacking.layer?.cornerCurve = .continuous
        keyChipBacking.addSubview(keyField)

        iconView.symbolConfiguration = .init(pointSize: 12, weight: .semibold)
        iconView.imageScaling = .scaleProportionallyDown

        titleField.font = .systemFont(ofSize: 13)
        // Hard single-line enforcement: never wrap, always truncate at the tail.
        titleField.lineBreakMode = .byTruncatingTail
        titleField.maximumNumberOfLines = 1
        titleField.usesSingleLineMode = true
        if let cell = titleField.cell as? NSTextFieldCell {
            cell.wraps = false
            cell.isScrollable = false
            cell.lineBreakMode = .byTruncatingTail
        }

        countField.font = .systemFont(ofSize: 10, weight: .medium)
        countChipBacking.wantsLayer = true
        countChipBacking.layer?.cornerCurve = .continuous
        countChipBacking.addSubview(countField)

        let stack = NSStackView(views: [keyChipBacking, iconView, titleField, countChipBacking])
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        keyField.translatesAutoresizingMaskIntoConstraints = false
        countField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            // Required equality: the stack spans the full row width so the
            // title receives a real, finite width after the key chip, icon
            // and count chip reserve their space.
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            keyField.centerXAnchor.constraint(equalTo: keyChipBacking.centerXAnchor),
            keyField.centerYAnchor.constraint(equalTo: keyChipBacking.centerYAnchor),
            keyChipBacking.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            keyChipBacking.heightAnchor.constraint(equalToConstant: 16),
            keyChipBacking.widthAnchor.constraint(equalTo: keyField.widthAnchor, constant: 10),
            countField.centerXAnchor.constraint(equalTo: countChipBacking.centerXAnchor),
            countField.centerYAnchor.constraint(equalTo: countChipBacking.centerYAnchor),
            countChipBacking.widthAnchor.constraint(equalTo: countField.widthAnchor, constant: 8),
            countChipBacking.heightAnchor.constraint(equalToConstant: 15),
            // One line of 13pt text, capped so nothing can spill past the
            // fixed 36pt row into neighbouring rows.
            titleField.heightAnchor.constraint(lessThanOrEqualToConstant: 18),
        ])
        // Only the title may shrink: key chip, icon and count chip keep
        // their intrinsic width, the title takes the remainder and
        // truncates at the tail.
        titleField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Belt and braces: clip any residual overflow at the cell bounds.
        clipsToBounds = true

        applyColors()
    }

    func configure(keyLabel: String, systemImage: String, labelText: String, extraFileCount: Int) {
        keyField.stringValue = keyLabel
        iconView.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
        titleField.stringValue = labelText
        if extraFileCount > 0 {
            countField.stringValue = L10n.tr("candidateBar.moreFiles", default: "+%lld more", extraFileCount)
            countChipBacking.isHidden = false
        } else {
            countChipBacking.isHidden = true
        }
        setAccessibilityLabel("\(keyLabel). \(labelText)")
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { applyColors() }
    }

    private func applyColors() {
        let emphasized = backgroundStyle == .emphasized || backgroundStyle == .lowered
        let textColor: NSColor = emphasized ? .white : .labelColor
        keyField.textColor = textColor
        titleField.textColor = textColor
        countField.textColor = textColor
        iconView.contentTintColor = emphasized ? .white : .secondaryLabelColor
        let chipColor: NSColor = emphasized
            ? .white.withAlphaComponent(0.28)
            : .labelColor.withAlphaComponent(0.08)
        keyChipBacking.layer?.backgroundColor = chipColor.cgColor
        countChipBacking.layer?.backgroundColor = chipColor.cgColor
        if emphasized {
            titleField.font = .systemFont(ofSize: 13, weight: .semibold)
        } else {
            titleField.font = .systemFont(ofSize: 13)
        }
        // Keep chips fully round regardless of width.
        keyChipBacking.layer?.cornerRadius = 8
        countChipBacking.layer?.cornerRadius = 7.5
    }
}

/// A candidate click is deliberate even while another application owns focus.
private final class CandidateNativeTableView: NSTableView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
