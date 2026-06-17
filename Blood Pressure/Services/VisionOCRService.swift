//
//  VisionOCRService.swift
//  Blood Pressure
//

import UIKit
import Vision

@MainActor
final class VisionOCRService {
    enum OCRError: LocalizedError {
        case invalidImage
        case noTextFound
        case processingFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not process the selected image."
            case .noTextFound:
                return "No text was detected in the image. Try a clearer photo."
            case .processingFailed(let message):
                return "OCR failed: \(message)"
            }
        }
    }

    func recognizeText(from image: UIImage) async throws -> OCRParsedResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        let lines = try await performOCR(on: cgImage)
        guard !lines.isEmpty else {
            throw OCRError.noTextFound
        }

        return BloodPressureOCRParser.parse(lines: lines)
    }

    private func performOCR(on cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.processingFailed(error.localizedDescription))
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations
                    // Vision does not guarantee text order; sort top-to-bottom, then left-to-right.
                    .sorted {
                        let lhsTopY = $0.boundingBox.maxY
                        let rhsTopY = $1.boundingBox.maxY
                        if abs(lhsTopY - rhsTopY) > 0.02 {
                            return lhsTopY > rhsTopY
                        }
                        return $0.boundingBox.minX < $1.boundingBox.minX
                    }
                    .compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }

                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.processingFailed(error.localizedDescription))
            }
        }
    }
}
