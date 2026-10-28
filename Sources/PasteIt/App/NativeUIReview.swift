import AppKit
import SwiftUI
import Vision
import PasteItCore

/// Explicit development-only real-window check, never started by ordinary
/// launches. Uses AppValidationSession and does not start clipboard monitoring,
/// login registration, analytics or global shortcuts.
@MainActor
struct NativeUIReview {
    func run(directory: URL) async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let app = NSApplication.shared
        let oldPolicy = app.activationPolicy()
        let oldBundle = L10n.bundle
        AppDelegate.configureLocalization()
        let resources = L10n.bundle
        L10n.bundle = try require(resources.path(forResource: "zh-Hans", ofType: "lproj").flatMap(Bundle.init(path:)))
        let runtime = AppRuntime.shared
        try check(runtime.historyStore.clips.allSatisfy { $0.plainText.hasPrefix("Synthetic note ") })
        app.setActivationPolicy(.regular)
        defer {
            OnboardingWindowController.shared.close()
            for window in app.windows where window.isVisible { window.orderOut(nil) }
            runtime.stop()
            L10n.bundle = oldBundle
            app.setActivationPolicy(oldPolicy)
        }
        SettingsWindowController.shared.show(appState: runtime.state)
        await settle()
        let settings = try require(app.windows.first { $0.isVisible && $0.title.contains("设置") })
        settings.appearance = NSAppearance(named: .aqua)
        settings.setContentSize(NSSize(width: 860, height: 660))
        settings.center()
        await settle()
        try snapshot(settings, name: "settings-general-light", directory: directory)
        try await press("剪贴板", in: settings)
        await settle()
        try snapshot(settings, name: "settings-clipboard-light", directory: directory)
        try check(await hasText("剪贴板与历史", in: settings))
        if ProcessInfo.processInfo.arguments.contains("--ui-review-preview-only") {
            for (size, label) in [(NSSize(width: 720, height: 500), "minimum"),
                                  (NSSize(width: 860, height: 660), "standard"),
                                  (NSSize(width: 1120, height: 760), "wide")] {
                settings.setContentSize(size)
                for style in ClipboardPresentationStyle.allCases {
                    runtime.settings.clipboardPresentationStyle = style
                    await settle()
                    try snapshot(settings, name: "preview-\(style.rawValue)-\(label)", directory: directory)
                }
            }
            settings.appearance = NSAppearance(named: .darkAqua)
            await settle()
            try snapshot(settings, name: "preview-candidate-dark", directory: directory)
            try "Both style previews rendered in minimum, standard and wide native settings windows; dark appearance checked. No clipboard access or cross-app input.\n".write(to: directory.appendingPathComponent("interaction-result.txt"), atomically: true, encoding: .utf8)
            return
        }
        runtime.settings.clipboardPresentationStyle = .candidateBar
        await settle()
        try check(await hasText("辅助功能", in: settings))
        try snapshot(settings, name: "settings-candidate-demo-light", directory: directory)
        try? await Task.sleep(for: .milliseconds(850))
        try snapshot(settings, name: "settings-candidate-demo-frame2", directory: directory)
        runtime.settings.clipboardPresentationStyle = .timeline
        await settle()
        try await press("OCR", in: settings)
        await settle()
        try snapshot(settings, name: "settings-ocr-light", directory: directory)
        try check(await hasText("图片文字识别", in: settings))
        try await press("快捷粘贴", in: settings)
        await settle()
        try snapshot(settings, name: "settings-quick-paste-light", directory: directory)
        try check(await hasText("启用快捷粘贴", in: settings))
        try await press("OCR", in: settings)
        await settle()
        settings.setContentSize(NSSize(width: 720, height: 500))
        await settle()
        try snapshot(settings, name: "settings-ocr-minimum", directory: directory)
        settings.setContentSize(NSSize(width: 860, height: 660))
        settings.appearance = NSAppearance(named: .darkAqua)
        try await press("剪贴板", in: settings)
        await settle()
        try snapshot(settings, name: "settings-clipboard-dark", directory: directory)

        OnboardingWindowController.shared.show(settings: runtime.settings, flow: .install, source: "synthetic_ui_review")
        await settle()
        let onboarding = try require(app.windows.first { $0.isVisible && $0.title == "Pastel it！" })
        onboarding.appearance = NSAppearance(named: .aqua)
        await settle()
        try snapshot(onboarding, name: "onboarding-capture-light", directory: directory)
        try check(await hasText("复制即保存", in: onboarding))
        try await press("继续", in: onboarding)
        await settle()
        try snapshot(onboarding, name: "onboarding-paste-light", directory: directory)
        try await press("上一步", in: onboarding)
        await settle()
        try check(await hasText("复制即保存", in: onboarding))
        try await press("继续", in: onboarding)
        await settle()
        try await press("继续", in: onboarding)
        await settle()
        try snapshot(onboarding, name: "onboarding-preview-light", directory: directory)
        try await press("继续", in: onboarding)
        await settle()
        onboarding.appearance = NSAppearance(named: .darkAqua)
        await settle()
        try snapshot(onboarding, name: "onboarding-organize-dark", directory: directory)
        try check(await hasText("开始使用", in: onboarding))
        try await press("开始使用", in: onboarding)
        await settle()
        try check(!OnboardingWindowController.shared.isVisible)
        try check(runtime.settings.hasCompletedOnboarding)
        settings.resignKey()
        settings.resignMain()
        NSApp.deactivate()
        await settle()
        try snapshot(settings, name: "settings-inactive-dark", directory: directory)
        NSApp.activate(ignoringOtherApps: true)

        // Review the prior native preview changes without touching the real clipboard.
        let image = NSImage(size: NSSize(width: 480, height: 200))
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 480, height: 200).fill()
        ("UI Review 4821" as NSString).draw(at: NSPoint(x: 35, y: 85), withAttributes: [.font: NSFont.systemFont(ofSize: 36), .foregroundColor: NSColor.black])
        image.unlockFocus()
        let tiff = try require(image.tiffRepresentation)
        let data = try require(NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]))
        let blob = try runtime.blobStore.store(data: data, preferredExtension: "png")
        let item = ClipItem(title: "Synthetic preview", primaryType: .image, pasteboardTypes: ["public.png"], blobRelativePath: blob,
                            ocrText: "UI Review 4821", imagePixelWidth: 480, imagePixelHeight: 200, contentHash: "synthetic-ui-preview")
        runtime.historyStore.context.insert(item)
        try runtime.historyStore.context.save()
        runtime.historyStore.refresh()
        let preview = NSWindow(contentRect: NSRect(x: 100, y: 120, width: 620, height: 380), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        preview.title = "Synthetic Image Preview"
        preview.isReleasedWhenClosed = false
        let previewHosting = NSHostingController(rootView: ClipQuickPreview(item: item, historyStore: runtime.historyStore, onClose: {}))
        previewHosting.sizingOptions = []
        preview.contentViewController = previewHosting
        preview.setContentSize(NSSize(width: 620, height: 380))
        preview.makeKeyAndOrderFront(nil)
        preview.center()
        await settle()
        try snapshot(preview, name: "image-preview-light", directory: directory)
        try await press("Text", in: preview)
        await settle()
        try snapshot(preview, name: "ocr-preview-light", directory: directory)
        try await press("Edit", in: preview)
        await settle()
        try check(await hasText("Save", in: preview))
        try await press("Cancel", in: preview)
        await settle()
        try check(item.ocrText == "UI Review 4821")
        try await press("Edit", in: preview)
        await settle()
        try await press("Save", in: preview)
        await settle()
        try check(item.ocrText == "UI Review 4821")
        preview.appearance = NSAppearance(named: .darkAqua)
        await settle()
        try snapshot(preview, name: "ocr-preview-dark", directory: directory)
        preview.close()

        // Exercise the actual candidate panel against a uniquely named board.
        let fileURL = runtime.blobStore.rootURL.appendingPathComponent("Synthetic-reference.txt")
        try Data("Synthetic UI review".utf8).write(to: fileURL)
        let file = ClipItem(title: "Synthetic file", primaryType: .file, pasteboardTypes: ["public.file-url"],
                            fileURLString: fileURL.absoluteString, contentHash: "ui-review-file")
        let note = ClipItem(title: "项目会议纪要", plainText: "项目会议纪要", primaryType: .text, pasteboardTypes: [], contentHash: "ui-review-note")
        runtime.historyStore.context.insert(file)
        runtime.historyStore.context.insert(note)
        try runtime.historyStore.context.save()
        runtime.historyStore.refresh()
        runtime.settings.clipboardPresentationStyle = .candidateBar
        runtime.settings.timelinePrimaryAction = .copyOnly
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let writer = PasteController(blobStore: runtime.blobStore, pasteboard: board)
        // Supply a genuine AppKit text insertion rectangle through the same
        // locator boundary, so visual placement can be checked without granting
        // this temporary development build access to other applications.
        let input = NSWindow(contentRect: NSRect(x: 100, y: 150, width: 1100, height: 580), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        input.isReleasedWhenClosed = false
        input.title = "Synthetic Caret Placement"
        input.center()
        let editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 1100, height: 580))
        editor.font = .systemFont(ofSize: 24)
        editor.textContainerInset = NSSize(width: 32, height: 42)
        editor.string = "在插入光标旁选择剪贴板内容"
        input.contentView = editor
        input.makeKeyAndOrderFront(nil)
        input.makeFirstResponder(editor)
        editor.setSelectedRange(NSRange(location: 0, length: 0))
        await settle()
        let caret = editor.firstRect(forCharacterRange: editor.selectedRange(), actualRange: nil)
        try check(caret.height > 0)
        try snapshot(input, name: "candidate-caret-input", directory: directory)
        let candidate = TimelinePanelController(appState: runtime.state, pasteController: writer, candidateAnchorProvider: { _ in caret })
        candidate.show()
        await settle()
        let bar = try require(app.windows.first { $0.isVisible && $0 is NSPanel && $0.title == "Pastel it！" })
        try check(bar.frame.maxY <= caret.minY - 5 || bar.frame.minY >= caret.maxY + 5)
        try check(abs(bar.frame.minX - caret.minX) < 1)
        bar.appearance = NSAppearance(named: .aqua)
        await settle()
        try check(candidate.candidatePageItems.count == 10)
        let nativeTable = try require(bar.contentView.flatMap { candidateTable(in: $0) })
        try check(nativeTable.numberOfRows == 10 && nativeTable.rowHeight == 36)
        try snapshot(bar, name: "candidate-page1-light", directory: directory)
        await waitForCapture("candidate-page1-light", directory: directory)
        let firstPageIDs = Set(candidate.candidatePageItems.map(\.id))
        let tab = try require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: bar.windowNumber, context: nil, characters: "\t", charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48))
        bar.sendEvent(tab)
        await settle()
        try check(candidate.candidatePageIndex == 1)
        try check(candidate.candidatePageItems.count == 10)
        try check(firstPageIDs.isDisjoint(with: candidate.candidatePageItems.map(\.id)))
        try snapshot(bar, name: "candidate-page2-light", directory: directory)
        await waitForCapture("candidate-page2-light", directory: directory)
        candidate.previousCandidatePage()
        await settle()
        try check(candidate.candidatePageIndex == 0)
        bar.appearance = NSAppearance(named: .darkAqua)
        await settle()
        try snapshot(bar, name: "candidate-page1-dark", directory: directory)
        let expected = candidate.candidatePageItems[2]
        let choose = try require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: bar.windowNumber, context: nil, characters: "3", charactersIgnoringModifiers: "3", isARepeat: false, keyCode: 20))
        bar.sendEvent(choose)
        for _ in 0..<100 {
            if !candidate.isVisible { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        try check(!candidate.isVisible)
        if expected.primaryType == .image {
            try check(board.data(forType: .png) == data)
        } else {
            try check(board.string(forType: .string) == (try require(expected.plainText)))
        }
        await settle()
        candidate.show()
        await settle()
        let clickedItem = try require(candidate.candidatePageItems.first)
        let table = try require(bar.contentView.flatMap { candidateTable(in: $0) })
        NSApp.activate(ignoringOtherApps: true)
        bar.makeKeyAndOrderFront(nil)
        await settle()
        let firstRow = table.rect(ofRow: 0)
        let click = table.convert(NSPoint(x: firstRow.midX, y: firstRow.midY), to: nil)
        try clickAt(click, in: bar)
        for _ in 0..<100 {
            if !candidate.isVisible { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        if candidate.isVisible { try snapshot(bar, name: "candidate-click-diagnostic", directory: directory) }
        try check(!candidate.isVisible)
        if clickedItem.primaryType == .image {
            try check(board.data(forType: .png) == data)
        } else {
            try check(board.string(forType: .string) == (try require(clickedItem.plainText)))
        }
        await settle()
        candidate.show()
        await settle()
        let textRow = try require(candidate.candidatePageItems.firstIndex { $0.primaryType == .text })
        let expectedText = candidate.candidatePageItems[textRow].plainText
        let textTable = try require(bar.contentView.flatMap { candidateTable(in: $0) })
        let textRect = textTable.rect(ofRow: textRow)
        try clickAt(textTable.convert(NSPoint(x: textRect.midX, y: textRect.midY), to: nil), in: bar)
        for _ in 0..<100 {
            if !candidate.isVisible { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        try check(!candidate.isVisible && board.string(forType: .string) == expectedText)
        await settle()
        candidate.show()
        await settle()
        for _ in 1..<candidate.candidatePageCount { candidate.nextCandidatePage() }
        await settle()
        try check(candidate.candidatePageItems.count == 1 && bar.frame.height < 110)
        try snapshot(bar, name: "candidate-tail-page", directory: directory)
        for _ in 1..<candidate.candidatePageCount { candidate.previousCandidatePage() }
        await settle()
        bar.setContentSize(NSSize(width: 320, height: 220))
        await settle()
        let down = try require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: bar.windowNumber, context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 125))
        for _ in 0..<9 { bar.sendEvent(down) }
        await settle()
        let compactTable = try require(bar.contentView.flatMap { candidateTable(in: $0) })
        try check(candidate.candidateSelectedID == candidate.candidatePageItems[9].id)
        try check(compactTable.visibleRect.contains(compactTable.rect(ofRow: 9)))
        try snapshot(bar, name: "candidate-constrained-scroll", directory: directory)
        candidate.hide()
        await settle()
        for (sample, name) in [(item, "candidate-image-preview"), (file, "candidate-file-preview")] {
            let detail = NSWindow(contentRect: NSRect(x: 100, y: 150, width: 320, height: 240), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            detail.isReleasedWhenClosed = false
            detail.title = "Synthetic Candidate Preview"
            let host = NSHostingController(rootView: CandidateHoverPreview(item: sample, blobStore: runtime.blobStore).padding(10))
            host.sizingOptions = []
            detail.contentViewController = host
            detail.setContentSize(NSSize(width: 320, height: 240))
            detail.makeKeyAndOrderFront(nil)
            detail.center()
            await settle()
            try snapshot(detail, name: name, directory: directory)
            detail.close()
        }
        input.close()
        runtime.settings.clipboardPresentationStyle = .timeline
        try "Native windows: settings grouped navigation, separate OCR/Quick Paste, light/dark/minimum/inactive appearance, two presentation demos and permission-button visibility, onboarding forward/back/finish, image/text tabs and OCR edit/cancel/save, candidate caret-relative vertical 10-row pages from a native text view, Tab next-page and previous-page with disjoint content, numeric selection, default-image and text native row clicks, short last-page sizing, constrained-window keyboard scrolling, and image/file preview content exercised. General clipboard and cross-app key synthesis were not used; candidate selection used a unique temporary pasteboard.\n".write(to: directory.appendingPathComponent("interaction-result.txt"), atomically: true, encoding: .utf8)
    }

    private func candidateTable(in view: NSView) -> NSTableView? {
        if let table = view as? NSTableView { return table }
        return view.subviews.lazy.compactMap { candidateTable(in: $0) }.first
    }

    private func clickAt(_ point: NSPoint, in window: NSWindow) throws {
        let eventTime = ProcessInfo.processInfo.systemUptime
        let up = try require(NSEvent.mouseEvent(with: .leftMouseUp, location: point, modifierFlags: [], timestamp: eventTime + 0.05,
            windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 0))
        let down = try require(NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: [], timestamp: eventTime,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        NSApp.postEvent(up, atStart: true)
        // Deliver both through AppKit's event queue; a direct sendEvent from
        // this task can enter NSTableView's tracking loop before activation
        // finishes and strand the synthetic mouseUp.
        NSApp.postEvent(down, atStart: true)
    }

    private struct ReviewFailure: Error, CustomStringConvertible {
        let description: String
    }

    private func require<T>(_ value: T?, _ message: String = "Required native review element is missing") throws -> T {
        guard let value else { throw ReviewFailure(description: message) }
        return value
    }

    private func check(_ condition: Bool, line: UInt = #line) throws {
        guard condition else { throw ReviewFailure(description: "Native review condition failed at line \(line)") }
    }

    private struct Element {
        let object: NSObject
        let role: String
        let text: String
        let frame: NSRect
    }

    private func elements(in window: NSWindow) -> [Element] {
        var result: [Element] = []
        var seen = Set<ObjectIdentifier>()
        func visit(_ object: Any, depth: Int) {
            guard depth < 30, result.count < 2000, let object = object as? NSObject,
                  seen.insert(ObjectIdentifier(object)).inserted else { return }
            if let element = object as? any NSAccessibilityProtocol {
                let text = [element.accessibilityLabel(), element.accessibilityTitle(), element.accessibilityValue() as? String]
                    .compactMap { $0 }.first { !$0.isEmpty } ?? ""
                result.append(Element(object: object, role: element.accessibilityRole()?.rawValue ?? "", text: text, frame: element.accessibilityFrame()))
                for child in element.accessibilityChildren() ?? [] { visit(child, depth: depth + 1) }
            }
            if let view = object as? NSView { for child in view.subviews { visit(child, depth: depth + 1) } }
        }
        visit(window, depth: 0)
        return result
    }

    private func normalized(_ text: String) -> String {
        text.filter { !$0.isWhitespace }.lowercased()
    }

    private func renderedWindow(_ window: NSWindow) throws -> (NSView, NSBitmapImageRep) {
        let view = try require(window.contentView?.superview ?? window.contentView)
        view.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        let bitmap = try require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        return (view, bitmap)
    }

    private func recognizedLabels(_ window: NSWindow, matching target: String? = nil) async throws -> [(String, NSPoint)] {
        let (view, bitmap) = try renderedWindow(window)
        let data = try require(bitmap.representation(using: .png, properties: [:]))
        let recognized = try await Task.detached(priority: .userInitiated) { () -> [(String, CGRect)] in
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.usesLanguageCorrection = false
            try VNImageRequestHandler(data: data).perform([request])
            return (request.results ?? []).compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                var text = candidate.string
                var rect = observation.boundingBox
                if let target, let range = text.range(of: target, options: .caseInsensitive),
                   let box = try? candidate.boundingBox(for: range) {
                    text = target
                    rect = box.boundingBox
                }
                return (text, rect)
            }
        }.value
        return recognized.map { text, rect in
            let point = NSPoint(x: rect.midX * view.bounds.width, y: rect.midY * view.bounds.height)
            return (text, view.convert(point, to: nil))
        }
    }

    private func hasText(_ text: String, in window: NSWindow) async -> Bool {
        if elements(in: window).contains(where: { normalized($0.text) == normalized(text) }) { return true }
        return (try? await recognizedLabels(window).contains { normalized($0.0).contains(normalized(text)) }) ?? false
    }

    private func press(_ text: String, in window: NSWindow) async throws {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        let candidates = elements(in: window).filter { $0.text == text && !$0.frame.isEmpty }
        if let node = candidates.first(where: { $0.role == "AXButton" || $0.role == "AXRadioButton" }),
           let modern = node.object as? any NSAccessibilityProtocol, modern.accessibilityPerformPress() { return }
        // Read the actual native rendering when SwiftUI virtualizes its AX nodes.
        // Events stay in this process/window and require no global AX permission.
        let labels = try await recognizedLabels(window, matching: text)
        let point = try require(labels.first { normalized($0.0) == normalized(text) }?.1,
                                "Missing visible native label: \(text)")
        let sidebarLabels: Set<String> = ["通用", "剪贴板", "OCR", "快捷粘贴", "文件夹", "隐私", "存储", "关于"]
        if sidebarLabels.contains(text), let content = window.contentView, let table = candidateTable(in: content) {
            let row = table.row(at: table.convert(point, from: nil))
            if row >= 0 {
                table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                return
            }
        }
        // AppKit controls can enter a tracking loop inside mouseDown. Queue
        // mouseUp first so that loop can consume it instead of waiting forever.
        let eventTime = ProcessInfo.processInfo.systemUptime
        let up = try require(NSEvent.mouseEvent(with: .leftMouseUp, location: point, modifierFlags: [], timestamp: eventTime + 0.05,
                                                windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 0))
        let down = try require(NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: [], timestamp: eventTime,
                                                  windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        NSApp.postEvent(up, atStart: true)
        window.sendEvent(down)
    }

    private func snapshot(_ window: NSWindow, name: String, directory: URL) throws {
        window.contentView?.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        try JSONSerialization.data(withJSONObject: ["pid": Int(ProcessInfo.processInfo.processIdentifier), "window": window.windowNumber, "isKeyWindow": window.isKeyWindow], options: [.sortedKeys])
            .write(to: directory.appendingPathComponent(name + ".window.json"))
        let records = elements(in: window).map { ["role": $0.role, "text": $0.text, "frame": NSStringFromRect($0.frame)] }
        try JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent(name + ".json"))
        let (_, bitmap) = try renderedWindow(window)
        let png = try require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: directory.appendingPathComponent(name + ".png"))
    }

    private func waitForCapture(_ name: String, directory: URL) async {
        for _ in 0..<200 {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent(name + ".continue").path) { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func settle() async {
        try? await Task.sleep(for: .milliseconds(450))
    }
}
