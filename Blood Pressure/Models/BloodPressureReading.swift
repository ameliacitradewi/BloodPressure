//
//  BloodPressureReading.swift
//  Blood Pressure
//

import Foundation
import SwiftData

@Model
final class BloodPressureReading {
    var id: UUID
    var systolic: Int
    var diastolic: Int
    var pulse: Int?
    var date: Date
    var notes: String
    var position: String
    var arm: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        systolic: Int,
        diastolic: Int,
        pulse: Int? = nil,
        date: Date = Date(),
        notes: String = "",
        position: String = MeasurementPosition.sitting.rawValue,
        arm: String = ArmUsed.leftArm.rawValue,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.systolic = systolic
        self.diastolic = diastolic
        self.pulse = pulse
        self.date = date
        self.notes = notes
        self.position = position
        self.arm = arm
        self.createdAt = createdAt
    }

    var category: BloodPressureCategory {
        BloodPressureCategory.classify(systolic: systolic, diastolic: diastolic)
    }

    var formattedBP: String {
        "\(systolic)/\(diastolic)"
    }
}
