//
//  CSVExporter.swift
//  Blood Pressure
//

import Foundation

enum CSVExporter {
    static func export(readings: [BloodPressureReading]) -> URL? {
        var csv = "Date,Systolic,Diastolic,Pulse,Status,Position,Arm,Notes\n"

        let formatter = ISO8601DateFormatter()
        for reading in readings.sorted(by: { $0.date > $1.date }) {
            let pulse = reading.pulse.map(String.init) ?? ""
            let escapedNotes = reading.notes.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(formatter.string(from: reading.date)),\(reading.systolic),\(reading.diastolic),\(pulse),\(reading.category.rawValue),\(reading.position),\(reading.arm),\"\(escapedNotes)\"\n"
        }

        let fileName = "blood_pressure_readings_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
