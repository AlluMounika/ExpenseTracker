//
//  ReceiptTextRecognizer.swift
//  ExpenseTracker
//

import UIKit
import Vision

enum ReceiptTextRecognizerError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: "The receipt image couldn't be read."
        }
    }
}

/// Runs Vision text recognition on a receipt and returns its text as lines, top to bottom.
struct ReceiptTextRecognizer {
    func recognizeLines(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw ReceiptTextRecognizerError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let fragments = try await Self.recognizeText(in: cgImage, orientation: orientation)
        return Self.groupIntoLines(fragments)
    }

    /// Text recognition is slow, so run it on a background queue instead of the main thread.
    nonisolated private static func recognizeText(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> [TextFragment] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                let fragments = (request.results ?? []).compactMap { observation -> TextFragment? in
                    guard let text = observation.topCandidates(1).first?.string else { return nil }
                    return TextFragment(text: text, box: observation.boundingBox)
                }
                continuation.resume(returning: fragments)
            }
        }
    }

    nonisolated private struct TextFragment: Sendable {
        let text: String
        let box: CGRect
    }

    /// Vision returns separate pieces for text on the same row (e.g. "TOTAL" and "$42.50"),
    /// so join pieces that sit at the same height into one line, left to right.
    private static func groupIntoLines(_ fragments: [TextFragment]) -> [String] {
        // Vision's coordinates start at the bottom-left, so a larger midY is higher on the receipt.
        let sorted = fragments.sorted { $0.box.midY > $1.box.midY }
        var lines: [[TextFragment]] = []

        for fragment in sorted {
            if let last = lines.last?.last,
               abs(last.box.midY - fragment.box.midY) < min(last.box.height, fragment.box.height) / 2 {
                lines[lines.count - 1].append(fragment)
            } else {
                lines.append([fragment])
            }
        }

        return lines.map { line in
            line.sorted { $0.box.minX < $1.box.minX }
                .map(\.text)
                .joined(separator: " ")
        }
    }
}

private extension CGImagePropertyOrientation {
    /// Vision needs the image's orientation to read photos that weren't taken upright.
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
