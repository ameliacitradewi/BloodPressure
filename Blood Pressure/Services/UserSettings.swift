//
//  UserSettings.swift
//  Blood Pressure
//

import Foundation

enum UserSettings {
    static let userNameKey = "userName"
    static let morningReminderEnabledKey = "morningReminderEnabled"
    static let eveningReminderEnabledKey = "eveningReminderEnabled"
    static let customReminderEnabledKey = "customReminderEnabled"
    static let morningReminderTimeKey = "morningReminderTime"
    static let eveningReminderTimeKey = "eveningReminderTime"
    static let customReminderTimeKey = "customReminderTime"

    static let healthDisclaimer =
        "This app is for tracking purposes only and does not provide medical diagnosis. Please consult a healthcare professional for medical advice."

    static func defaultMorningTime() -> Date {
        Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    }

    static func defaultEveningTime() -> Date {
        Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    }

    static func defaultCustomTime() -> Date {
        Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    }
}
