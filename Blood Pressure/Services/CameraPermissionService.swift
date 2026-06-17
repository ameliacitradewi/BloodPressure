//
//  CameraPermissionService.swift
//  Blood Pressure
//

import AVFoundation

enum CameraPermissionService {
    static func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    static var isAuthorized: Bool {
        authorizationStatus() == .authorized
    }

    static var isDenied: Bool {
        let status = authorizationStatus()
        return status == .denied || status == .restricted
    }
}
