//
//  AddReadingView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData
import PhotosUI

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
    
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCameraPermissionDenied = false
    @State private var selectedImage: UIImage?
    
    @State private var isProcessingOCR = false
    @State private var ocrResult: OCRParsedResult?
    @State private var showOCRReview = false
    @State private var ocrErrorMessage: String?
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

                            if let ocrErrorMessage {
                                Text(ocrErrorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 4)
                            }

                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                    }

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
                if isProcessingOCR {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()

                        ProgressView("Reading image...")
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    selectedImage = image
                    Task { await processImage(image) }
                }
            }
            .sheet(isPresented: $showOCRReview) {
                if let ocrResult {
                    OCRResultReviewView(
                        ocrResult: ocrResult,
                        date: $date,
                        notes: $notes,
                        position: $position,
                        arm: $arm,
                        onSave: { sys, dia, pul in
                            systolic = String(sys)
                            diastolic = String(dia)
                            pulse = pul.map(String.init) ?? ""

                            self.ocrResult = OCRParsedResult(
                                systolic: sys,
                                diastolic: dia,
                                pulse: pul,
                                rawLines: ocrResult.rawLines
                            )

                            showOCRReview = false
                            saveReading()
                        }
                    )
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
                guard let newItem else { return }
                Task { await loadPhoto(from: newItem) }
            }
        }
    }
    
    private var inputModePicker: some View {
        HStack(spacing: 4) {
            ForEach(InputMode.allCases) { mode in
                Button {
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
        guard let result = ocrResult else { return false }

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
    }
    
    private func openCamera() async {
        let status = CameraPermissionService.authorizationStatus()
        
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            let granted = await CameraPermissionService.requestAccess()
            if granted {
                showCamera = true
            } else {
                showCameraPermissionDenied = true
            }
        case .denied, .restricted:
            showCameraPermissionDenied = true
        @unknown default:
            showCameraPermissionDenied = true
        }
    }
    
    private var scanCameraPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.06, green: 0.09, blue: 0.15))

            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .black.opacity(0.05),
                                        .black.opacity(0.20)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(.subheadline, weight: .bold))

                            Text("Image loaded")
                                .font(.system(.subheadline, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                        .padding(18)
                    }
            } else {
                VStack(spacing: 18) {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            Color.white.opacity(0.55),
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [7, 6],
                                dashPhase: 0
                            )
                        )
                        .frame(height: 120)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "camera")
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.55))

                                Text("Point at your BP monitor display")
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.55))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 70)
                }
            }
        }
        .frame(height: 240)
    }
    
    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            ocrErrorMessage = "Could not load the selected photo."
            return
        }
        
        selectedImage = image
        await processImage(image)
    }
    
    private var saveButton: some View {
        Button {
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
                Task { await openCamera() }
            } label: {
                Label("Use Camera", systemImage: "camera")
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
        isProcessingOCR = true
        ocrErrorMessage = nil
        ocrResult = nil
        validationError = nil
        hasTriedToSave = false

        systolic = ""
        diastolic = ""
        pulse = ""

        defer {
            isProcessingOCR = false
        }

        do {
            let result = try await fastVLMService.recognize(
                from: image
            )

            ocrResult = result

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

            showOCRReview = false

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
        ocrResult = nil
        ocrErrorMessage = nil
        validationError = nil
        selectedPhotoItem = nil
        selectedImage = nil
        inputMode = .manual
        hasTriedToSave = false
    }
}

#Preview {
    AddReadingView2()
        .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
