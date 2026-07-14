//
//  ReminderNotification.swift
//  Blood Pressure
//
//  Created by Amelia Citra on 14/07/26.
//

import Foundation

struct ReminderNotification: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var timeInterval: TimeInterval
    var isEnabled: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        time: Date,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.timeInterval = time.timeIntervalSince1970
        self.isEnabled = isEnabled
    }

    var time: Date {
        get {
            Date(timeIntervalSince1970: timeInterval)
        }

        set {
            timeInterval = newValue.timeIntervalSince1970
        }
    }

    var notificationIdentifier: String {
        "bp_reminder_\(id)"
    }
}
