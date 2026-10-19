import SwiftUI
import PasteItCore

struct OCRSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var manager: HotkeyManager

    private let languages = ["zh-Hans", "zh-Hant", "en-US", "ja-JP", "ko-KR", "fr-FR", "de-DE", "es-ES"]

    private func ocr<Value>(_ key: WritableKeyPath<OCRConfiguration, Value>) -> Binding<Value> {
        Binding(get: { settings.ocrConfiguration[keyPath: key] }, set: {
            var value = settings.ocrConfiguration
            value[keyPath: key] = $0
            settings.ocrConfiguration = value
        })
    }

    private func scope(_ key: WritableKeyPath<QuickPasteScope, Bool>) -> Binding<Bool> {
        Binding(get: { settings.quickPasteScope[keyPath: key] }, set: {
            var value = settings.quickPasteScope
            value[keyPath: key] = $0
            settings.quickPasteScope = value
        })
    }

    var body: some View {
        Form {
            Section(L10n.tr("ocr.recognition", default: "Image Recognition")) {
                Toggle(L10n.tr("ocr.enabled", default: "Enable OCR"), isOn: ocr(\.enabled))
                Text(L10n.tr("ocr.enabledHelp", default: "Recognize new images in the background. Existing results are kept when OCR is off. Re-run an image to apply changed settings."))
                    .font(.caption).foregroundStyle(.secondary)
                Group {
                    Toggle(L10n.tr("ocr.tables", default: "Recognize tables"), isOn: ocr(\.detectsTables))
                        .disabled(!supportsTables)
                    Text(L10n.tr("ocr.tablesHelp", default: "On macOS 26 or later, output detected tables as Markdown and keep surrounding text."))
                        .font(.caption).foregroundStyle(.secondary)
                    Toggle(L10n.tr("ocr.automaticLanguage", default: "Detect languages automatically"), isOn: Binding(
                        get: { settings.ocrConfiguration.languages.isEmpty },
                        set: { automatic in
                            var value = settings.ocrConfiguration
                            value.languages = automatic ? [] : ["zh-Hans", "en-US", "ja-JP"]
                            settings.ocrConfiguration = value
                        }
                    ))
                    if !settings.ocrConfiguration.languages.isEmpty {
                        ForEach(languages, id: \.self) { language in
                            Toggle(Locale.current.localizedString(forIdentifier: language) ?? language,
                                   isOn: Binding(get: { settings.ocrConfiguration.languages.contains(language) }, set: { selected in
                                var value = settings.ocrConfiguration
                                if selected { value.languages.append(language) }
                                else { value.languages.removeAll { $0 == language } }
                                settings.ocrConfiguration = value
                            }))
                            .toggleStyle(.checkbox)
                        }
                    }
                    Picker(L10n.tr("ocr.accuracy", default: "Recognition mode"), selection: ocr(\.accuracy)) {
                        Text(L10n.tr("ocr.accurate", default: "Accurate")).tag(OCRConfiguration.Accuracy.accurate)
                        Text(L10n.tr("ocr.fast", default: "Fast")).tag(OCRConfiguration.Accuracy.fast)
                    }
                    Toggle(L10n.tr("ocr.correction", default: "Language correction"), isOn: ocr(\.languageCorrection))
                    LabeledContent(L10n.tr("ocr.minimumHeight", default: "Minimum text height")) {
                        HStack {
                            Slider(value: ocr(\.minimumTextHeight), in: 0...0.1, step: 0.001)
                                .frame(width: 150)
                                .accessibilityLabel(L10n.tr("ocr.minimumHeight", default: "Minimum text height"))
                            Text(settings.ocrConfiguration.minimumTextHeight, format: .percent.precision(.fractionLength(1)))
                                .monospacedDigit().frame(width: 48, alignment: .trailing)
                        }
                    }
                    Text(L10n.tr("ocr.parametersHelp", default: "Text height is a fraction of image height; 0% keeps small text. Fast mode supports fewer languages; selected languages use accurate mode when needed. Document table detection uses its own system model."))
                        .font(.caption).foregroundStyle(.secondary)
                }
                .disabled(!settings.ocrConfiguration.enabled)
                Button(L10n.tr("ocr.reset", default: "Reset OCR Settings")) { settings.ocrConfiguration = .init() }
            }
            Section(L10n.tr("quickPaste.title", default: "Quick Paste")) {
                Toggle(L10n.tr("quickPaste.enabled", default: "Enable quick paste"), isOn: Binding(
                    get: { settings.quickPasteEnabled },
                    set: { enabled in
                        if manager.setQuickPasteEnabled(enabled) { settings.quickPasteEnabled = enabled }
                    }
                ))
                Text(L10n.tr("quickPaste.help", default: "Convert the current system clipboard to plain text and paste it. This shortcut is separate from Open Paste. The default is ⇧⌘V; change either shortcut if they conflict."))
                    .font(.caption).foregroundStyle(.secondary)
                ShortcutSettingsView(manager: manager, actions: [.quickPaste], showsReset: false)
                Toggle(L10n.tr("quickPaste.text", default: "Text → plain text"), isOn: scope(\.text)).toggleStyle(.checkbox)
                Toggle(L10n.tr("quickPaste.images", default: "Images → OCR text"), isOn: scope(\.images)).toggleStyle(.checkbox)
                Toggle(L10n.tr("quickPaste.files", default: "Files → file names"), isOn: scope(\.fileNames)).toggleStyle(.checkbox)
                Text(L10n.tr("quickPaste.scopeHelp", default: "Only selected types are converted. Images follow the OCR settings above. Without Accessibility, plain text is prepared for manual ⌘V. Automatic pasting restores the original clipboard unless you copy something newer."))
                    .font(.caption).foregroundStyle(.secondary)
                if settings.quickPasteScope.isEmpty {
                    Text(L10n.tr("quickPaste.emptyScope", default: "Select at least one content type to use quick paste."))
                        .font(.caption).foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .pasteItGlassButtonStyle()
    }

    private var supportsTables: Bool {
        if #available(macOS 26.0, *) { return true }
        return false
    }
}
