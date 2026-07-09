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
    
    @State private var isProcessingOCR = false
    @State private var ocrResult: OCRParsedResult?
    @State private var showOCRReview = false
    @State private var ocrErrorMessage: String?
    @State private var showSaveSuccess = false
    @State private var validationError: String?
    
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

                    if inputMode == .manual {
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
    
    private var scanSection: some View {
        Group {
            Section("Scan from Image") {
                Button {
                    Task { await openCamera() }
                } label: {
                    Label("Scan from Camera", systemImage: "camera.fill")
                }
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Choose from Gallery", systemImage: "photo.on.rectangle")
                }
            }
            
            if showCameraPermissionDenied {
                Section {
                    PermissionDeniedView(
                        title: "Camera Access Required",
                        message: "Please enable camera access in Settings to scan your blood pressure monitor.",
                        systemImage: "camera.fill"
                    )
                }
            }
            
            if let ocrResult {
                Section("Extracted Values (Review before saving)") {
                    LabeledContent("Systolic", value: ocrResult.systolic.map(String.init) ?? "—")
                    LabeledContent("Diastolic", value: ocrResult.diastolic.map(String.init) ?? "—")
                    LabeledContent("Pulse", value: ocrResult.pulse.map(String.init) ?? "—")
                    
                    Button("Review & Edit") {
                        showOCRReview = true
                    }
                    
                    if !ocrResult.rawLines.isEmpty {
                        DisclosureGroup("Raw OCR Text") {
                            ForEach(ocrResult.rawLines, id: \.self) { line in
                                Text(line)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                Section {
                    Text("Take or choose a photo of your blood pressure monitor. You'll review the extracted values before saving.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
    
    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            ocrErrorMessage = "Could not load the selected photo."
            return
        }
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
    
    private func processImage(_ image: UIImage) async {
        isProcessingOCR = true
        ocrErrorMessage = nil
        ocrResult = nil

        defer {
            isProcessingOCR = false
        }

        do {
            let result = try await fastVLMService.recognize(
                from: image
            )

            ocrResult = result
            showOCRReview = true

        } catch {
            ocrErrorMessage = error.localizedDescription
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
        inputMode = .manual
        hasTriedToSave = false
    }
}

#Preview {
    AddReadingView2()
        .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
