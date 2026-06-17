//
//  TrendInsights.swift
//  Blood Pressure
//

import Foundation

enum TrendInsights {
    static func generate(for readings: [BloodPressureReading]) -> String {
        guard readings.count >= 2 else {
            return "Add more readings to see personalized insights."
        }

        let sorted = readings.sorted { $0.date < $1.date }
        let midpoint = sorted.count / 2
        let earlier = Array(sorted.prefix(midpoint))
        let recent = Array(sorted.suffix(from: midpoint))

        guard !earlier.isEmpty, !recent.isEmpty else {
            return "Your blood pressure data is being collected."
        }

        let earlierAvgSys = Double(earlier.map(\.systolic).reduce(0, +)) / Double(earlier.count)
        let recentAvgSys = Double(recent.map(\.systolic).reduce(0, +)) / Double(recent.count)
        let difference = recentAvgSys - earlierAvgSys

        if abs(difference) < 3 {
            return "Your blood pressure is stable this week."
        } else if difference > 0 {
            return "Your systolic pressure increased slightly."
        } else {
            return "Your systolic pressure decreased slightly."
        }
    }
}
