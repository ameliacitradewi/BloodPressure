//
//  HomePallete.swift
//  Blood Pressure
//
//  Created by Amelia Citra on 10/07/26.
//

import SwiftUI

enum HomePalette {
    static let background = Color(
        red: 0.955,
        green: 0.965,
        blue: 0.985
    )

    static let primaryText = Color(
        red: 0.09,
        green: 0.13,
        blue: 0.25
    )

    static let secondaryText = Color(
        red: 0.39,
        green: 0.47,
        blue: 0.63
    )

    static let tertiaryText = Color(
        red: 0.68,
        green: 0.73,
        blue: 0.83
    )

    static let primaryBlue = Color(
        red: 0.16,
        green: 0.35,
        blue: 0.58
    )

    static let heroStart = Color(
        red: 0.16,
        green: 0.35,
        blue: 0.57
    )

    static let heroEnd = Color(
        red: 0.10,
        green: 0.22,
        blue: 0.40
    )

    static let systolic = Color(
        red: 0.15,
        green: 0.32,
        blue: 0.56
    )

    static let diastolic = Color(
        red: 0.48,
        green: 0.30,
        blue: 0.90
    )

    static let pulse = Color(
        red: 0.96,
        green: 0.23,
        blue: 0.43
    )

    // MARK: - Blood pressure category colors
    static let low = Color.blue
    static let normal = Color.green
    static let elevated = Color.yellow
    static let hypertensionStage1 = Color.orange
    static let hypertensionStage2 = Color.red
    static let hypertensiveCrisis = Color.brown

    static func categoryColor(
        for category: BloodPressureCategory
    ) -> Color {
        switch category {
        case .low: return low
        case .normal: return normal
        case .elevated: return elevated
        case .hypertensionStage1: return hypertensionStage1
        case .hypertensionStage2: return hypertensionStage2
        case .hypertensiveCrisis: return hypertensiveCrisis
        }
    }

    // MARK: - Gauge colors
    static let gaugeGreen = Color.green
    static let gaugeYellow = Color.yellow
    static let gaugeOrange = Color.orange
    static let gaugeNeedle = Color.black
//    (
//        red: 0.06,
//        green: 0.13,
//        blue: 0.27
//    )
}
