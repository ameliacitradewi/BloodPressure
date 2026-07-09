//
//  InlineCamera.swift
//  Blood Pressure
//
//  Created by Amelia Citra on 09/07/26.
//

//
//  InlineCameraView.swift
//  Blood Pressure
//

import SwiftUI
import AVFoundation
import UIKit
import Observation

@Observable
final class InlineCameraController: NSObject {
    let session = AVCaptureSession()

    var errorMessage: String?

    private let sessionQueue = DispatchQueue(label: "InlineCamera.SessionQueue")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage) -> Void)?
    private var isConfigured = false

    func configureIfNeeded() {
        guard !isConfigured else { return }

        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            defer {
                self.session.commitConfiguration()
            }

            guard
                let camera = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                )
            else {
                DispatchQueue.main.async {
                    self.errorMessage = "Back camera is not available."
                }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                self.isConfigured = true
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func start() {
        configureIfNeeded()

        sessionQueue.async {
            guard self.isConfigured else { return }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        captureCompletion = completion

        let settings: AVCapturePhotoSettings

        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            settings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
            )
        } else {
            settings = AVCapturePhotoSettings()
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension InlineCameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            DispatchQueue.main.async {
                self.errorMessage = "Could not capture photo."
            }
            return
        }

        DispatchQueue.main.async {
            self.captureCompletion?(image)
            self.captureCompletion = nil
        }
    }
}

struct InlineCameraView: UIViewRepresentable {
    var camera: InlineCameraController

    func makeUIView(context: Context) -> InlineCameraPreviewView {
        let view = InlineCameraPreviewView()
        view.previewLayer.session = camera.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: InlineCameraPreviewView, context: Context) {
        uiView.previewLayer.session = camera.session
    }
}

final class InlineCameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
