//
//  AddReadingView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import UIKit

struct AddReadingView2: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputMode: InputMode = .manual
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var pulse = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var position: MeasurementPosition = .sitting
    @State private var arm: ArmUsed = .leftArm
    
    @State private var hasTriedToSave = false
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCameraPermissionDenied = false
    @State private var selectedImage: UIImage?
    @State private var inlineCamera = InlineCameraController()
    @State private var cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    @State private var isProcessingFastVLM = false
    @State private var fastVLMResult: OCRParsedResult?
    @State private var fastVLMErrorMessage: String?
    @State private var showSaveSuccess = false
    @State private var validationError: String?
    @State private var showUnreadableImageAlert = false
    @State private var unreadableImageAlertMessage = ""
    
    @StateObject private var fastVLMService = FastVLMService()
    
    enum InputMode: String, CaseIterable, Identifiable {
        case manual = "Manual"
        case scan = "Scan"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.96, blue: 0.98)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            inputModePicker

                            if inputMode == .manual {
                                ReadingFormFields2(
                                    systolic: $systolic,
                                    diastolic: $diastolic,
                                    pulse: $pulse,
                                    date: $date,
                                    notes: $notes,
                                    position: $position,
                                    arm: $arm,
                                    showValidationErrors: hasTriedToSave
                                )
                            } else {
                                scanSection
                            }

                            if let validationError {
                                Text(validationError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 4)
                            }

                            if let fastVLMErrorMessage {
                                Text(fastVLMErrorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 4)
                            }

                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                        .background(
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    dismissKeyboard()
                                }
                        )
                    }
                    .scrollDismissesKeyboard(.interactively)

                    if inputMode == .manual || hasReadableFastVLMResult {
                        saveButton
                            .padding(.horizontal, 16)
                            .padding(.bottom, 18)
                            .background(
                                Color(red: 0.94, green: 0.96, blue: 0.98)
                                    .ignoresSafeArea(edges: .bottom)
                            )
                    }
                }
            }
            .navigationTitle("Log Reading")
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if isProcessingFastVLM {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()

                        ProgressView("Reading image...")
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .alert("Reading Saved", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) {
                    resetForm()
                }
            } message: {
                Text("Your blood pressure reading has been saved.")
            }
            .alert("Could Not Read Image", isPresented: $showUnreadableImageAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(unreadableImageAlertMessage)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                dismissKeyboard()
                
                guard let newItem else { return }
                Task { await loadPhoto(from: newItem) }
            }
        }
    }
    
    private var inputModePicker: some View {
        HStack(spacing: 4) {
            ForEach(InputMode.allCases) { mode in
                Button {
                    dismissKeyboard()
                    
                    withAnimation(.snappy) {
                        inputMode = mode
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode == .manual ? "doc.text" : "camera")
                            .font(.system(.subheadline, weight: .semibold))
//                            .font(.system(size: 15, weight: .semibold))

                        Text(mode.rawValue)
                            .font(.system(.subheadline, weight: .semibold))
//                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(inputMode == mode ? Color(red: 0.12, green: 0.30, blue: 0.53) : Color(red: 0.45, green: 0.52, blue: 0.64))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        if inputMode == mode {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.90, green: 0.93, blue: 0.97))
        )
    }
    
    private var hasReadableFastVLMResult: Bool {
        guard let result = fastVLMResult else { return false }

        let hasSystolic = (result.systolic ?? 0) > 0
        let hasDiastolic = (result.diastolic ?? 0) > 0

        return hasSystolic && hasDiastolic
    }
    
    private var scanSection: some View {
        VStack(spacing: 22) {
            scanCameraPreview

            scanActionButtons

            if showCameraPermissionDenied {
                PermissionDeniedView(
                    title: "Camera Access Required",
                    message: "Please enable camera access in Settings to scan your blood pressure monitor.",
                    systemImage: "camera.fill"
                )
            }
            
            if hasReadableFastVLMResult {
                ReadingFormFields2(
                    systolic: $systolic,
                    diastolic: $diastolic,
                    pulse: $pulse,
                    date: $date,
                    notes: $notes,
                    position: $position,
                    arm: $arm,
                    showValidationErrors: hasTriedToSave
                )
            }
        }
        .onAppear {
            refreshCameraAuthorizationStatus()

            if cameraAuthorizationStatus == .authorized {
                inlineCamera.start()
            }
        }
        .onDisappear {
            inlineCamera.stop()
        }
    }
    
    private func refreshCameraAuthorizationStatus() {
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        showCameraPermissionDenied = cameraAuthorizationStatus == .denied || cameraAuthorizationStatus == .restricted
    }

    private func handleCameraButtonTapped() {
        refreshCameraAuthorizationStatus()

        switch cameraAuthorizationStatus {
        case .authorized:
            captureInlineCameraPhoto()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    showCameraPermissionDenied = !granted

                    if granted {
                        inlineCamera.start()
                    }
                }
            }

        case .denied, .restricted:
            showCameraPermissionDenied = true

        @unknown default:
            showCameraPermissionDenied = true
        }
    }

    private func captureInlineCameraPhoto() {
        inlineCamera.capturePhoto { image in
            selectedImage = image

            Task {
                await processImage(image)
            }
        }
    }
    
    private var scanCameraPreview: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = width * 3 / 4
            let guideWidth = width * 0.82
            let guideHeight = height * 0.58

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.06, green: 0.09, blue: 0.15))

                if cameraAuthorizationStatus == .authorized {
                    InlineCameraView(camera: inlineCamera)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                    
                    scanHelpText
                } else {
                    scanPlaceholder
                }

                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        Color.white.opacity(0.72),
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [7, 6],
                            dashPhase: 0
                        )
                    )
                    .frame(width: guideWidth, height: guideHeight)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
    }
    
    private var scanPlaceholder: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.viewfinder")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))

            Text("Allow camera access\nto use this feature")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }
    
    private var scanHelpText: some View {
        VStack {
            Text("Make sure your device\nis inside this frame")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
//                .background(
//                    Capsule()
//                        .fill(.black.opacity(0.35))
//                )
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            fastVLMErrorMessage = "Could not load the selected photo."
            return
        }
        
        selectedImage = image
        await processImage(image)
    }
    
    private var saveButton: some View {
        Button {
            dismissKeyboard()
            hasTriedToSave = true
            saveReading()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(.headline, weight: .bold))
//                    .font(.system(size: 18, weight: .bold))

                Text("Save Reading")
                    .font(.system(.headline, weight: .bold))
//                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.13, green: 0.30, blue: 0.52))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var scanActionButtons: some View {
        HStack(spacing: 16) {
            Button {
                dismissKeyboard()
                handleCameraButtonTapped()
            } label: {
                Label(
                    cameraAuthorizationStatus == .authorized ? "Take Photo" : "Use Camera",
                    systemImage: cameraAuthorizationStatus == .authorized ? "camera.fill" : "camera"
                )
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.20, green: 0.36, blue: 0.58))
                )
            }
            .buttonStyle(.plain)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                Label("From Gallery", systemImage: "photo")
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(Color(red: 0.20, green: 0.36, blue: 0.58))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(red: 0.91, green: 0.95, blue: 0.99))
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func processImage(_ image: UIImage) async {
        isProcessingFastVLM = true
        fastVLMErrorMessage = nil
        fastVLMResult = nil
        validationError = nil
        hasTriedToSave = false

        systolic = ""
        diastolic = ""
        pulse = ""

        defer {
            isProcessingFastVLM = false
        }

        do {
            let result = try await fastVLMService.recognize(
                from: image
            )

            fastVLMResult = result

            guard (result.systolic ?? 0) > 0,
                  (result.diastolic ?? 0) > 0 else {
                unreadableImageAlertMessage = "Please make sure the blood pressure monitor display is clear, bright, and fully inside the frame."
                showUnreadableImageAlert = true
                return
            }

            if let systolicValue = result.systolic {
                systolic = String(systolicValue)
            }

            if let diastolicValue = result.diastolic {
                diastolic = String(diastolicValue)
            }

            if let pulseValue = result.pulse, pulseValue > 0 {
                pulse = String(pulseValue)
            }

        } catch {
            unreadableImageAlertMessage = error.localizedDescription
            showUnreadableImageAlert = true
        }
    }
    
    private func saveReading() {
        guard let validated = ReadingFormValidator.validate(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse
        ) else {
            validationError = "Please enter valid systolic and diastolic values."
            return
        }
        
        validationError = nil
        
        let reading = BloodPressureReading(
            systolic: validated.0,
            diastolic: validated.1,
            pulse: validated.2,
            date: date,
            notes: notes,
            position: position.rawValue,
            arm: arm.rawValue
        )
        
        modelContext.insert(reading)
        showSaveSuccess = true
    }
    
    private func resetForm() {
        systolic = ""
        diastolic = ""
        pulse = ""
        date = Date()
        notes = ""
        position = .sitting
        arm = .leftArm
        fastVLMResult = nil
        fastVLMErrorMessage = nil
        validationError = nil
        selectedPhotoItem = nil
        selectedImage = nil
        inputMode = .manual
        hasTriedToSave = false
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    AddReadingView2()
        .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
