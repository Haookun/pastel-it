import AppKit
import Foundation
import ImageIO
import PasteItCore
@preconcurrency import Vision

enum OCRService {
    private static let modernRecognitionQueue = ModernRecognitionQueue()
    // Bound Vision work when several images arrive together. Capture and history
    // insertion do not wait for this queue; OCR updates the searchable clip later.
    private static let recognitionQueue = DispatchQueue(label: "app.pasteit.ocr", qos: .utility)

    static func recognizeText(in image: NSImage, configuration: OCRConfiguration = .init()) async -> String? {
        guard configuration.enabled else { return nil }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        return await recognizeText(in: cgImage, configuration: configuration.normalized)
    }

    static func recognizeText(in imageData: Data, configuration: OCRConfiguration = .init()) async -> String? {
        guard configuration.enabled else { return nil }
        let configuration = configuration.normalized
        if #available(macOS 15.0, *) {
            return await modernRecognitionQueue.recognizeText(in: imageData, configuration: configuration)
        }
        return await withCheckedContinuation { continuation in
            recognitionQueue.async {
                let text: String? = autoreleasepool {
                    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                        return nil
                    }
                    return recognizeTextSynchronously(in: cgImage, configuration: configuration)
                }
                continuation.resume(returning: text)
            }
        }
    }

    private static func recognizeText(in cgImage: CGImage, configuration: OCRConfiguration) async -> String? {
        if #available(macOS 15.0, *),
           let imageData = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) {
            return await modernRecognitionQueue.recognizeText(in: imageData, configuration: configuration)
        }
        return await withCheckedContinuation { continuation in
            recognitionQueue.async {
                let text = autoreleasepool {
                    recognizeTextSynchronously(in: cgImage, configuration: configuration)
                }
                continuation.resume(returning: text)
            }
        }
    }

    /// Runs only on recognitionQueue. A synchronous request has a single result
    /// path, including Vision errors, so the continuation is resumed exactly once.
    private static func recognizeTextSynchronously(in cgImage: CGImage, configuration: OCRConfiguration) -> String? {
        let request = VNRecognizeTextRequest()
        // Clipboard images can contain any language. Let Vision choose its model
        // instead of restricting recognition to a fixed language list.
        request.recognitionLevel = configuration.accuracy == .accurate ? .accurate : .fast
        request.automaticallyDetectsLanguage = configuration.languages.isEmpty
        request.usesLanguageCorrection = configuration.languageCorrection
        if !configuration.languages.isEmpty {
            if configuration.accuracy == .fast,
               let supported = try? request.supportedRecognitionLanguages(),
               !configuration.languages.allSatisfy({ supported.contains($0) }) {
                request.recognitionLevel = .accurate
            }
            request.recognitionLanguages = configuration.languages
        }
        request.minimumTextHeight = Float(configuration.minimumTextHeight)
        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
            let text = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }
}

/// Chain requests so actor reentrancy cannot start several Vision jobs at once.
private actor ModernRecognitionQueue {
    private var pendingRequest: Task<String?, Never>?

    @available(macOS 15.0, *)
    func recognizeText(in imageData: Data, configuration: OCRConfiguration) async -> String? {
        let previous = pendingRequest
        let current = Task<String?, Never> {
            _ = await previous?.value
            var request = RecognizeTextRequest()
            request.recognitionLevel = configuration.accuracy == .accurate ? .accurate : .fast
            request.automaticallyDetectsLanguage = configuration.languages.isEmpty
            request.usesLanguageCorrection = configuration.languageCorrection
            if !configuration.languages.isEmpty {
                let languages = configuration.languages.map { Locale.Language(identifier: $0) }
                if configuration.accuracy == .fast {
                    let supported = Set(request.supportedRecognitionLanguages.map(\.minimalIdentifier))
                    if !languages.allSatisfy({ supported.contains($0.minimalIdentifier) }) {
                        request.recognitionLevel = .accurate
                    }
                }
                request.recognitionLanguages = languages
            }
            request.minimumTextHeightFraction = Float(configuration.minimumTextHeight)
            do {
                let observations = try await request.perform(on: imageData)
                let lines = observations.compactMap { observation -> OCRTableText.Line? in
                    guard let text = observation.topCandidates(1).first?.string else { return nil }
                    return OCRTableText.Line(text: text, bounds: observation.boundingBox.cgRect)
                }
                guard !lines.isEmpty else { return nil }
                if #available(macOS 26.0, *), configuration.detectsTables {
                    let tables = await recognizeTables(in: imageData, lines: lines, configuration: configuration)
                    return OCRTableText.compose(lines: lines, tables: tables)
                }
                return OCRTableText.compose(lines: lines, tables: [])
            } catch {
                return nil
            }
        }
        pendingRequest = current
        return await current.value
    }

    @available(macOS 26.0, *)
    private func recognizeTables(in imageData: Data, lines: [OCRTableText.Line], configuration: OCRConfiguration) async -> [OCRTableText.Table] {
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.automaticallyDetectLanguage = configuration.languages.isEmpty
        if !configuration.languages.isEmpty {
            request.textRecognitionOptions.recognitionLanguages = configuration.languages.map { Locale.Language(identifier: $0) }
        }
        request.textRecognitionOptions.minimumTextHeightFraction = Float(configuration.minimumTextHeight)
        request.textRecognitionOptions.useLanguageCorrection = configuration.languageCorrection
        request.barcodeDetectionOptions.enabled = false
        do {
            let documents = try await request.perform(on: imageData)
            return documents.flatMap { observation in
                observation.document.tables.map { table in
                    let rows = table.rows.indices.map { row in
                        table.columns.indices.map { column in
                            guard let cell = table.cell(row: row, col: column),
                                  cell.rowRange.lowerBound == row,
                                  cell.columnRange.lowerBound == column else { return "" }
                            // A spanning cell appears once, at its top-left anchor.
                            return OCRTableText.cellText(
                                lines: lines, bounds: cell.content.boundingRegion.boundingBox.cgRect,
                                fallback: cell.content.text.transcript
                            )
                        }
                    }
                    return OCRTableText.Table(rows: rows, bounds: table.boundingRegion.boundingBox.cgRect)
                }
            }
        } catch {
            // Table detection is optional: retain successful text OCR on failure.
            return []
        }
    }
}
