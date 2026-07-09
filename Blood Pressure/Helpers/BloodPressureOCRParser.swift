//
//  BloodPressureOCRParser.swift
//  Blood Pressure
//

import Foundation

struct OCRParsedResult {
    var systolic: Int?
    var diastolic: Int?
    var pulse: Int?
    var rawLines: [String]

    var hasAnyValue: Bool {
        systolic != nil || diastolic != nil || pulse != nil
    }
}
