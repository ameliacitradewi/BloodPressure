//
//  EditReadingView.swift
//  Blood Pressure
//

import SwiftUI

struct EditReadingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var reading: BloodPressureReading
    
    @State private var systolic: String
    @State private var diastolic: String
    @State private var pulse: String
    @State private var date: Date
    @State private var notes: String
    @State private var position: MeasurementPosition
    @State private var arm: ArmUsed
    @State private var validationError: String?
    
    @State private var hasTriedToSave = false
    
    init(reading: BloodPressureReading) {
        self.reading = reading
        _systolic = State(initialValue: String(reading.systolic))
        _diastolic = State(initialValue: String(reading.diastolic))
        _pulse = State(initialValue: reading.pulse.map(String.init) ?? "")
        _date = State(initialValue: reading.date)
        _notes = State(initialValue: reading.notes)
        _position = State(initialValue: MeasurementPosition(rawValue: reading.position) ?? .sitting)
        _arm = State(initialValue: ArmUsed(rawValue: reading.arm) ?? .leftArm)
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                if let validationError {
                    Section {
                        Text(validationError)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let validated = ReadingFormValidator.validate(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse
        ) else {
            validationError = "Please enter valid values."
            return
        }
        
        reading.systolic = validated.0
        reading.diastolic = validated.1
        reading.pulse = validated.2
        reading.date = date
        reading.notes = notes
        reading.position = position.rawValue
        reading.arm = arm.rawValue
        
        dismiss()
    }
}
