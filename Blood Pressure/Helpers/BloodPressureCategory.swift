//
//  BloodPressureCategory.swift
//  Blood Pressure
//

import SwiftUI

enum BloodPressureCategory: String, CaseIterable {
    case low = "Low"
    case normal = "Normal"
    case elevated = "Elevated"
    case hypertensionStage1 = "Hypertension Stage 1"
    case hypertensionStage2 = "Hypertension Stage 2"
    case hypertensiveCrisis = "Hypertensive Crisis"

    var color: Color {
        HomePalette.categoryColor(for: self)
    }

    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .normal: return "checkmark.circle.fill"
        case .elevated: return "exclamationmark.circle.fill"
        case .hypertensionStage1: return "exclamationmark.triangle.fill"
        case .hypertensionStage2: return "exclamationmark.octagon.fill"
        case .hypertensiveCrisis: return "bolt.heart.fill"
        }
    }

    /// Classifies blood pressure using AHA guidelines.
    static func classify(systolic: Int, diastolic: Int) -> BloodPressureCategory {
        if systolic > 180 || diastolic > 120 {
            return .hypertensiveCrisis
        }
        if systolic >= 140 || diastolic >= 90 {
            return .hypertensionStage2
        }
        if systolic >= 130 || diastolic >= 80 {
            return .hypertensionStage1
        }
        if systolic >= 120 && diastolic < 80 {
            return .elevated
        }
        if systolic < 90 || diastolic < 60 {
            return .low
        }
        return .normal
    }
}
