//
//  HomeViewModel.swift
//  Blood Pressure
//
//  Created by Amelia Citra on 13/07/26.
//

import Foundation
import SwiftUI

struct HomeViewModel {
    let readings: [BloodPressureReading]
    let userName: String
    
    var lastReading: BloodPressureReading? {
        readings.first
    }
    
    var recentReadings: [BloodPressureReading] {
        Array(readings.prefix(5))
    }
    
    var sevenDayReadings: [BloodPressureReading] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return readings.filter { reading in
            reading.date >= cutoff
        }
    }
    
    var sevenDayAverageSystolic: Int? {
        guard !sevenDayReadings.isEmpty else { return nil }
        return sevenDayReadings.map(\.systolic).reduce(0, +) / sevenDayReadings.count
    }
    
    var sevenDayAverageDiastolic: Int? {
        guard !sevenDayReadings.isEmpty else { return nil }
        return sevenDayReadings.map(\.diastolic).reduce(0, +) / sevenDayReadings.count
    }
    
    var sevenDayAveragePulse: Int? {
        let pulseValues = sevenDayReadings.compactMap(\.pulse)
        guard !pulseValues.isEmpty else { return nil }
        return pulseValues.reduce(0, +) / pulseValues.count
    }
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        default: timeGreeting = "Good evening"
        }
        
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "\(timeGreeting)!"
        }
        
        return "\(timeGreeting), \(trimmedName)!"
    }
    
    func readableCategory(
        _ category: BloodPressureCategory
    ) -> String {
        category.rawValue
            .replacingOccurrences(of: "\n", with: " ")
    }
    
    func categoryColor(for category: BloodPressureCategory) -> Color {
        category.color
    }
    
    func categoryProgress(for category: BloodPressureCategory) -> Double {
        switch category {
        case .low: return 0.01
        case .normal: return 0.30
        case .elevated: return 0.48
        case .hypertensionStage1: return 0.75
        case .hypertensionStage2: return 0.86
        case .hypertensiveCrisis: return 0.97
        }
    }
    
    func shortDateTime(_ date: Date) -> String {
        let datePart = date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
        )
        
        let timePart = date.formatted(
            .dateTime
                .hour()
                .minute()
        )
        
        return "\(datePart) · \(timePart)"
    }
    
    
    var previousReading: BloodPressureReading? {
        guard readings.count > 1 else { return nil }
        return readings[1]
    }
    
    var latestReadingTrend: BloodPressureTrend {
        guard let currentReading = lastReading,
              let previousReading else {
            return .flat
        }
        
        return bloodPressureTrend(
            current: currentReading,
            previous: previousReading
        )
    }
    
    func bloodPressureTrend(current: BloodPressureReading, previous: BloodPressureReading) -> BloodPressureTrend {
        let systolicDelta = current.systolic - previous.systolic
        let diastolicDelta = current.diastolic - previous.diastolic

        if systolicDelta == 0 && diastolicDelta == 0 {
            return .flat
        }

        if systolicDelta <= 0 && diastolicDelta <= 0 {
            return .down
        }

        if systolicDelta >= 0 && diastolicDelta >= 0 {
            return .up
        }

        let currentScore = current.systolic + current.diastolic
        let previousScore = previous.systolic + previous.diastolic

        if currentScore < previousScore {
            return .down
        }

        if currentScore > previousScore {
            return .up
        }

        return .flat
    }
}


enum BloodPressureTrend {
    case up
    case down
    case flat

    var systemImageName: String {
        switch self {
        case .up:
            return "chart.line.uptrend.xyaxis"
        case .down:
            return "chart.line.downtrend.xyaxis"
        case .flat:
            return "chart.line.flattrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return HomePalette.elevated
        case .down: return HomePalette.normal
        case .flat: return HomePalette.elevated
        }
    }
}
