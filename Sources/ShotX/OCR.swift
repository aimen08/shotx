import AppKit
import Vision

enum OCR {
    // Runs Apple's Vision text recognizer on the given image and hands back the
    // recognized string. Accurate mode, language correction on, runs off the main
    // actor. Lines are joined with newlines to preserve the reading order.
    static func recognize(in cgImage: CGImage) async -> String? {
        await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            // A sensible default set — Vision auto-detects within these and
            // falls back to English. Skips the deprecated per-revision lookup.
            request.recognitionLanguages = ["en-US", "fr-FR", "es-ES", "de-DE", "it-IT", "pt-BR"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                return nil
            }

            guard let observations = request.results, !observations.isEmpty else {
                return nil
            }

            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }.value
    }

    @MainActor
    static func cgImage(from image: NSImage) -> CGImage? {
        var rect = NSRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    // Full user-facing flow: show "recognizing" toast, run recognition off-main,
    // copy to clipboard on success, and show a result toast either way.
    @MainActor
    static func runAndCopy(from cgImage: CGImage) async {
        ToastController.shared.show(
            message: "Recognizing text…",
            icon: "doc.text.viewfinder",
            tint: .systemBlue,
            duration: 1.0
        )
        let recognized = await recognize(in: cgImage)
        guard let text = recognized, !text.isEmpty else {
            ToastController.shared.show(
                message: "No text found",
                icon: "text.magnifyingglass",
                tint: .systemOrange
            )
            return
        }
        ImageSaver.copyTextToClipboard(text)
        let lineCount = text.components(separatedBy: "\n").count
        let summary = lineCount == 1
            ? "Text copied to clipboard"
            : "Text copied to clipboard (\(lineCount) lines)"
        ToastController.shared.show(
            message: summary,
            icon: "doc.on.doc.fill",
            tint: .systemGreen
        )
    }
}
