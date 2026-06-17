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
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func scheduleReminders(
        morningEnabled: Bool,
        morningTime: Date,
        eveningEnabled: Bool,
        eveningTime: Date,
        customEnabled: Bool,
        customTime: Date
    ) async {
        center.removeAllPendingNotificationRequests()

        guard authorizationStatus == .authorized else { return }

        if morningEnabled {
            await scheduleDailyReminder(
                id: "morning_reminder",
                title: "Morning Blood Pressure Check",
                body: "Time to record your morning blood pressure reading.",
                time: morningTime
            )
        }

        if eveningEnabled {
            await scheduleDailyReminder(
                id: "evening_reminder",
                title: "Evening Blood Pressure Check",
                body: "Time to record your evening blood pressure reading.",
                time: eveningTime
            )
        }

        if customEnabled {
            await scheduleDailyReminder(
                id: "custom_reminder",
                title: "Blood Pressure Reminder",
                body: "Don't forget to log your blood pressure.",
                time: customTime
            )
        }
    }

    private func scheduleDailyReminder(id: String, title: String, body: String, time: Date) async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await center.add(request)
    }
}
