//
//  MeasurementEnums.swift
//  Blood Pressure
//

import Foundation

enum MeasurementPosition: String, CaseIterable, Identifiable {
    case sitting = "Sitting"
    case lyingDown = "Lying Down"
    case standing = "Standing"

    var id: String { rawValue }
}

enum ArmUsed: String, CaseIterable, Identifiable {
    case leftArm = "Left Arm"
    case rightArm = "Right Arm"

    var id: String { rawValue }
}
