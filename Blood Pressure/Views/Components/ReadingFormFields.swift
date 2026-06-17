//
//  ReadingFormFields.swift
//  Blood Pressure
//

import SwiftUI

struct ReadingFormFields: View {
    @Binding var systolic: String
    @Binding var diastolic: String
    @Binding var pulse: String
    @Binding var date: Date
    @Binding var notes: String
    @Binding var position: MeasurementPosition
    @Binding var arm: ArmUsed

    var body: some View {
        Section("Blood Pressure") {
            TextField("Systolic", text: $systolic)
                .keyboardType(.numberPad)
            TextField("Diastolic", text: $diastolic)
                .keyboardType(.numberPad)
            TextField("Pulse (optional)", text: $pulse)
                .keyboardType(.numberPad)
        }

        Section("Details") {
            DatePicker("Date & Time", selection: $date)

            Picker("Position", selection: $position) {
                ForEach(MeasurementPosition.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }

            Picker("Arm Used", selection: $arm) {
                ForEach(ArmUsed.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }

            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

enum ReadingFormValidator {
    static func validate(systolic: String, diastolic: String, pulse: String) -> (Int, Int, Int?)? {
        guard let sys = Int(systolic), let dia = Int(diastolic) else { return nil }
        guard (50...300).contains(sys), (30...200).contains(dia), sys > dia else { return nil }

        if pulse.isEmpty {
            return (sys, dia, nil)
        }

        guard let pulseValue = Int(pulse), (30...220).contains(pulseValue) else { return nil }
        return (sys, dia, pulseValue)
    }
}
