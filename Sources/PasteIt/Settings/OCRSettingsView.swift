import SwiftUI
import PasteItCore

struct OCRSettingsView: View {
    @ObservedObject var settings: AppSettings
    private let languages = ["zh-Hans", "zh-Hant", "en-US", "ja-JP", "ko-KR", "fr-FR", "de-DE", "es-ES"]

    private func ocr<Value>(_ key: WritableKeyPath<OCRConfiguration, Value>) -> Binding<Value> {
        Binding(get: { settings.ocrConfiguration[keyPath: key] }, set: {
            var value = settings.ocrConfiguration
            value[keyPath: key] = $0
            settings.ocrConfiguration = value
        })
    }

    var body: some View {
        Form {
            Section {
                Toggle(L10n.tr("ocr.enabled", default: "Enable OCR"), isOn: ocr(\.enabled))
            } header: {
                Text(L10n.tr("ocr.recognition", default: "Image Recognition"))
            } footer: {
                Text(L10n.tr("ocr.enabledHelp", default: "Recognize new images in the background. Existing results are kept when OCR is off. Re-run an image to apply changed settings."))
            }
            Section(L10n.tr("ocr.languages", default: "Languages")) {
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
            }
            .disabled(!settings.ocrConfiguration.enabled)
            Section {
                Toggle(L10n.tr("ocr.tables", default: "Recognize tables"), isOn: ocr(\.detectsTables))
                    .disabled(!supportsTables)
            } footer: {
                Text(L10n.tr("ocr.tablesHelp", default: "On macOS 26 or later, output detected tables as Markdown and keep surrounding text."))
            }
            .disabled(!settings.ocrConfiguration.enabled)
            Section {
                Picker(L10n.tr("ocr.accuracy", default: "Recognition mode"), selection: ocr(\.accuracy)) {
                    Text(L10n.tr("ocr.accurate", default: "Accurate")).tag(OCRConfiguration.Accuracy.accurate)
                    Text(L10n.tr("ocr.fast", default: "Fast")).tag(OCRConfiguration.Accuracy.fast)
                }
                Toggle(L10n.tr("ocr.correction", default: "Language correction"), isOn: ocr(\.languageCorrection))
                DisclosureGroup(L10n.tr("settings.group.advanced", default: "Advanced")) {
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
                Button(L10n.tr("ocr.reset", default: "Reset OCR Settings")) { settings.ocrConfiguration = .init() }
            }
            .disabled(!settings.ocrConfiguration.enabled)
        }
        .formStyle(.grouped)
    }

    private var supportsTables: Bool {
        if #available(macOS 26.0, *) { return true }
        return false
    }
}
