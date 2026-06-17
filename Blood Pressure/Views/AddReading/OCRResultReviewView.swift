//
//  OCRResultReviewView.swift
//  Blood Pressure
//

import SwiftUI

struct OCRResultReviewView: View {
  @Environment(\.dismiss) private var dismiss

  let ocrResult: OCRParsedResult
  @Binding var date: Date
  @Binding var notes: String
  @Binding var position: MeasurementPosition
  @Binding var arm: ArmUsed
  let onSave: (Int, Int, Int?) -> Void

  @State private var systolic: String
  @State private var diastolic: String
  @State private var pulse: String
  @State private var validationError: String?

  init(
    ocrResult: OCRParsedResult,
    date: Binding<Date>,
    notes: Binding<String>,
    position: Binding<MeasurementPosition>,
    arm: Binding<ArmUsed>,
    onSave: @escaping (Int, Int, Int?) -> Void
  ) {
    self.ocrResult = ocrResult
    self._date = date
    self._notes = notes
    self._position = position
    self._arm = arm
    self.onSave = onSave
    self._systolic = State(initialValue: ocrResult.systolic.map(String.init) ?? "")
    self._diastolic = State(initialValue: ocrResult.diastolic.map(String.init) ?? "")
    self._pulse = State(initialValue: ocrResult.pulse.map(String.init) ?? "")
  }

  var body: some View {
    NavigationStack {
      Form {
        if !ocrResult.hasAnyValue {
          Section {
            Text("Could not confidently extract values. Please enter them manually.")
              .font(.subheadline)
              .foregroundStyle(.orange)
          }
        }

        ReadingFormFields(
          systolic: $systolic,
          diastolic: $diastolic,
          pulse: $pulse,
          date: $date,
          notes: $notes,
          position: $position,
          arm: $arm
        )

        if !ocrResult.rawLines.isEmpty {
          Section("Detected Text") {
            ForEach(ocrResult.rawLines, id: \.self) { line in
              Text(line)
                .font(.caption)
            }
          }
        }

        if let validationError {
          Section {
            Text(validationError)
              .foregroundStyle(.red)
              .font(.caption)
          }
        }
      }
      .navigationTitle("Review OCR Result")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Confirm & Save") {
            confirmAndSave()
          }
        }
      }
    }
  }

  private func confirmAndSave() {
    guard let validated = ReadingFormValidator.validate(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse
    ) else {
      validationError = "Please enter valid values before saving."
      return
    }

    onSave(validated.0, validated.1, validated.2)
    dismiss()
  }
}
