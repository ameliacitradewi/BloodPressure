//
//  FastVLMBloodPressureService.swift
//  Blood Pressure
//

import Combine
import CoreImage
import Foundation
import MLX
import MLXLMCommon
import MLXRandom
import MLXVLM
import UIKit

@MainActor
final class FastVLMService: ObservableObject {
    enum FastVLMError: LocalizedError {
        case invalidImage
        case notBloodPressureMonitor
        case unclearDisplay
        case missingMeasurements
        case invalidMeasurements
        case invalidResponse(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "The selected image could not be processed."
                
            case .notBloodPressureMonitor:
                return """
                The image does not appear to contain a digital blood \
                pressure monitor.
                """
                
            case .unclearDisplay:
                return """
                The blood pressure monitor display is not clear enough. \
                Please move closer and avoid glare.
                """
                
            case .missingMeasurements:
                return """
                Systolic, diastolic, or pulse could not be read. \
                Please take another photo.
                """
                
            case .invalidMeasurements:
                return """
                The detected values are not valid. \
                Please review the image or take another photo.
                """
                
            case .invalidResponse(let response):
                return """
                FastVLM returned an invalid response:
                
                \(response)
                """
            }
        }
    }
    
    private enum LoadState {
        case idle
        case loaded(ModelContainer)
    }
    
    private struct ModelResponse: Decodable {
        let isBloodPressureMonitor: Bool?
        let isClear: Bool?
        let systolic: Int?
        let diastolic: Int?
        let pulse: Int?
        
        enum CodingKeys: String, CodingKey {
            case isBloodPressureMonitor = "is_blood_pressure_monitor"
            case isClear = "is_clear"
            case systolic
            case diastolic
            case pulse
        }
    }
    
    private static let prompt = """
    The attached image is the only source of truth.
    
        Inspect the digital blood pressure monitor display carefully.
    
        Extract the currently displayed:
        - systolic blood pressure
        - diastolic blood pressure
        - pulse rate
    
        Return one valid JSON object containing exactly these keys:
    
        "is_blood_pressure_monitor"
        "is_clear"
        "systolic"
        "diastolic"
        "pulse"
    
        Requirements:
        - The first two values must be booleans.
        - Each measurement must be an integer copied directly from the image,
          or 0 when it cannot be read confidently.
        - Do not use typical, normal, assumed, or example blood pressure values.
        - Do not guess missing or unclear digits.
        - Ignore date, time, memory number, user number, icons, and old readings.
        - Read the large measurement digits currently shown on the LCD.
        - Return JSON only.
        - Do not include markdown, comments, or explanations.
    """
    
    private let modelConfiguration = FastVLM.modelConfiguration
    
    private let generationParameters = GenerateParameters(
        temperature: 0.0
    )
    
    private let maximumTokens = 240
    
    private var loadState: LoadState = .idle
    
    init() {
        FastVLM.register(
            modelFactory: VLMModelFactory.shared
        )
    }
    
    func preload() async throws {
        _ = try await loadContainer()
    }
    
    func recognize(
        from image: UIImage
    ) async throws -> OCRParsedResult {
        let preparedCIImage = try makeDemoCompatibleImage(
            from: image
        )
        
#if DEBUG
        print("========== FASTVLM IMAGE INPUT ==========")
        print("UIImage size:", image.size)
        print("UIImage scale:", image.scale)
        print("UIImage orientation:", image.imageOrientation.rawValue)
        print("Prepared CIImage extent:", preparedCIImage.extent)
        print("=========================================")
#endif
        
        let userInput = UserInput(
            prompt: .text(Self.prompt),
            images: [
                .ciImage(preparedCIImage)
            ]
        )
        
        let container = try await loadContainer()
        
        MLXRandom.seed(
            UInt64(
                Date.timeIntervalSinceReferenceDate * 1000
            )
        )
        
        let parameters = generationParameters
        let tokenLimit = maximumTokens
        
        let generationResult = try await container.perform {
            context in
            
            let preparedInput = try await context.processor.prepare(
                input: userInput
            )
            
            return try MLXLMCommon.generate(
                input: preparedInput,
                parameters: parameters,
                context: context
            ) { tokens in
                
                if Task.isCancelled {
                    return .stop
                }
                
                if tokens.count >= tokenLimit {
                    return .stop
                }
                
                return .more
            }
        }
        
        let rawResponse = generationResult.output
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
#if DEBUG
        print("========== FASTVLM RAW RESPONSE ==========")
        print(rawResponse)
        print("==========================================")
#endif
        
        return try parseResponse(rawResponse)
    }
    
    private func loadContainer() async throws -> ModelContainer {
        switch loadState {
        case .loaded(let container):
            return container
            
        case .idle:
            
            MLX.GPU.set(
                cacheLimit: 20 * 1024 * 1024
            )
            
            let container =
            try await VLMModelFactory.shared.loadContainer(
                configuration: modelConfiguration
            ) { progress in
                
#if DEBUG
                let percentage = Int(
                    progress.fractionCompleted * 100
                )
                
                print(
                    "FastVLM loading:",
                    "\(percentage)%"
                )
#endif
            }
            
            loadState = .loaded(container)
            
            return container
        }
    }
    
    private func makeUprightCIImage(
        from image: UIImage
    ) throws -> CIImage {
        
        let renderSize = image.size
        
        guard
            renderSize.width > 0,
            renderSize.height > 0
        else {
            throw FastVLMError.invalidImage
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(
            size: renderSize,
            format: format
        )
        
        let normalizedImage = renderer.image { context in
            let bounds = CGRect(
                origin: .zero,
                size: renderSize
            )
            
            context.cgContext.setFillColor(
                UIColor.black.cgColor
            )
            
            context.cgContext.fill(bounds)
            
            image.draw(in: bounds)
        }
        
        guard let cgImage = normalizedImage.cgImage else {
            throw FastVLMError.invalidImage
        }
        
        return CIImage(cgImage: cgImage)
    }
    
    private func makeDemoCompatibleImage(
        from image: UIImage
    ) throws -> CIImage {
        
        let uprightImage = try makeUprightCIImage(
            from: image
        )
        
        let extent = uprightImage.extent.integral
        
        guard
            extent.width > 0,
            extent.height > 0
        else {
            throw FastVLMError.invalidImage
        }
        
        let targetAspectRatio: CGFloat = 4.0 / 3.0
        let currentAspectRatio =
        extent.width / extent.height
        
        let cropRect: CGRect
        
        if currentAspectRatio > targetAspectRatio {
            let cropWidth =
            extent.height * targetAspectRatio
            
            cropRect = CGRect(
                x: extent.midX - cropWidth / 2,
                y: extent.minY,
                width: cropWidth,
                height: extent.height
            )
            
        } else {
            let cropHeight =
            extent.width / targetAspectRatio
            
            cropRect = CGRect(
                x: extent.minX,
                y: extent.midY - cropHeight / 2,
                width: extent.width,
                height: cropHeight
            )
        }
        
        let croppedImage = uprightImage
            .cropped(to: cropRect)
            .transformed(
                by: CGAffineTransform(
                    translationX: -cropRect.minX,
                    y: -cropRect.minY
                )
            )
        
        let targetWidth: CGFloat = 640
        let targetHeight: CGFloat = 480
        
        let scaleX =
        targetWidth / croppedImage.extent.width
        
        let scaleY =
        targetHeight / croppedImage.extent.height
        
        let resizedImage = croppedImage.transformed(
            by: CGAffineTransform(
                scaleX: scaleX,
                y: scaleY
            )
        )
        
        return resizedImage.cropped(
            to: CGRect(
                x: 0,
                y: 0,
                width: targetWidth,
                height: targetHeight
            )
        )
    }
    
    private func parseResponse(
        _ rawResponse: String
    ) throws -> OCRParsedResult {
        guard
            let openingBrace =
                rawResponse.firstIndex(of: "{"),
            let closingBrace =
                rawResponse.lastIndex(of: "}"),
            openingBrace <= closingBrace
        else {
            throw FastVLMError.invalidResponse(
                rawResponse
            )
        }
        
        let jsonString = String(
            rawResponse[openingBrace...closingBrace]
        )
        
        guard
            let jsonData = jsonString.data(
                using: .utf8
            )
        else {
            throw FastVLMError.invalidResponse(
                rawResponse
            )
        }
        
        let response: ModelResponse
        
        do {
            response = try JSONDecoder().decode(
                ModelResponse.self,
                from: jsonData
            )
        } catch {
#if DEBUG
            print(
                "FastVLM JSON decoding error:",
                error
            )
#endif
            
            throw FastVLMError.invalidResponse(
                rawResponse
            )
        }
        
        guard
            response.isBloodPressureMonitor == true
        else {
            throw FastVLMError.notBloodPressureMonitor
        }
        
        guard response.isClear == true else {
            throw FastVLMError.unclearDisplay
        }
        
        guard
            let systolic = response.systolic,
            let diastolic = response.diastolic,
            let pulse = response.pulse,
            systolic > 0,
            diastolic > 0,
            pulse > 0
        else {
            throw FastVLMError.missingMeasurements
        }
        
        guard systolic > diastolic else {
            throw FastVLMError.invalidMeasurements
        }
        
        return OCRParsedResult(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            rawLines: [
                rawResponse
            ]
        )
    }
}
