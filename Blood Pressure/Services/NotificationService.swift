//
//  NotificationService.swift
//  Blood Pressure
//

import Foundation
import Combine
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [
                    .alert,
                    .sound,
                    .badge
                ]
            )

            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func scheduleReminders(
        _ reminders: [ReminderNotification]
    ) async {
        center.removeAllPendingNotificationRequests()

        guard authorizationStatus == .authorized else {
            return
        }

        for reminder in reminders where reminder.isEnabled {
            await scheduleDailyReminder(
                id: reminder.notificationIdentifier,
                title: reminder.notificationTitle,
                body: "Time to log your blood pressure reading.",
                time: reminder.time
            )
        }
    }

    private func scheduleDailyReminder(
        id: String,
        title: String,
        body: String,
        time: Date
    ) async {
        let components = Calendar.current.dateComponents(
            [
                .hour,
                .minute
            ],
            from: time
        )

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }
}
