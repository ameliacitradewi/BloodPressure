//
//  ReminderView.swift
//  Blood Pressure
//

import SwiftUI
import UserNotifications

struct ReminderView: View {
  @StateObject private var notificationService = NotificationService()

  @AppStorage(UserSettings.morningReminderEnabledKey) private var morningEnabled = false
  @AppStorage(UserSettings.eveningReminderEnabledKey) private var eveningEnabled = false
  @AppStorage(UserSettings.customReminderEnabledKey) private var customEnabled = false

  @AppStorage(UserSettings.morningReminderTimeKey) private var morningTimeInterval = UserSettings.defaultMorningTime().timeIntervalSince1970
  @AppStorage(UserSettings.eveningReminderTimeKey) private var eveningTimeInterval = UserSettings.defaultEveningTime().timeIntervalSince1970
  @AppStorage(UserSettings.customReminderTimeKey) private var customTimeInterval = UserSettings.defaultCustomTime().timeIntervalSince1970

  @State private var showPermissionDenied = false

  private var morningTime: Binding<Date> {
    timeBinding(for: $morningTimeInterval)
  }

  private var eveningTime: Binding<Date> {
    timeBinding(for: $eveningTimeInterval)
  }

  private var customTime: Binding<Date> {
    timeBinding(for: $customTimeInterval)
  }

  var body: some View {
    Form {
      if showPermissionDenied || notificationService.authorizationStatus == .denied {
        Section {
          PermissionDeniedView(
            title: "Notifications Disabled",
            message: "Please enable notifications in Settings to receive blood pressure reminders.",
            systemImage: "bell.slash.fill"
          )
        }
      }

      Section("Morning Reminder") {
        Toggle("Enable Morning Reminder", isOn: $morningEnabled)
          .onChange(of: morningEnabled) { _, _ in
            Task { await updateReminders() }
          }

        if morningEnabled {
          DatePicker("Time", selection: morningTime, displayedComponents: .hourAndMinute)
            .onChange(of: morningTimeInterval) { _, _ in
              Task { await updateReminders() }
            }
        }
      }

      Section("Evening Reminder") {
        Toggle("Enable Evening Reminder", isOn: $eveningEnabled)
          .onChange(of: eveningEnabled) { _, _ in
            Task { await updateReminders() }
          }

        if eveningEnabled {
          DatePicker("Time", selection: eveningTime, displayedComponents: .hourAndMinute)
            .onChange(of: eveningTimeInterval) { _, _ in
              Task { await updateReminders() }
            }
        }
      }

      Section("Custom Reminder") {
        Toggle("Enable Custom Reminder", isOn: $customEnabled)
          .onChange(of: customEnabled) { _, _ in
            Task { await updateReminders() }
          }

        if customEnabled {
          DatePicker("Time", selection: customTime, displayedComponents: .hourAndMinute)
            .onChange(of: customTimeInterval) { _, _ in
              Task { await updateReminders() }
            }
        }
      }

      Section {
        Text("Reminders use native iOS notifications. You will be asked for permission when enabling your first reminder.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Reminders")
    .task {
      await notificationService.refreshAuthorizationStatus()
      showPermissionDenied = notificationService.authorizationStatus == .denied
    }
  }

  private func timeBinding(for storage: Binding<TimeInterval>) -> Binding<Date> {
    Binding(
      get: { Date(timeIntervalSince1970: storage.wrappedValue) },
      set: { storage.wrappedValue = $0.timeIntervalSince1970 }
    )
  }

  private func updateReminders() async {
    let needsPermission = morningEnabled || eveningEnabled || customEnabled

    if needsPermission && notificationService.authorizationStatus == .notDetermined {
      let granted = await notificationService.requestPermission()
      if !granted {
        showPermissionDenied = true
        morningEnabled = false
        eveningEnabled = false
        customEnabled = false
        return
      }
    }

    if notificationService.authorizationStatus == .denied {
      showPermissionDenied = true
      return
    }

    await notificationService.scheduleReminders(
      morningEnabled: morningEnabled,
      morningTime: Date(timeIntervalSince1970: morningTimeInterval),
      eveningEnabled: eveningEnabled,
      eveningTime: Date(timeIntervalSince1970: eveningTimeInterval),
      customEnabled: customEnabled,
      customTime: Date(timeIntervalSince1970: customTimeInterval)
    )
  }
}

#Preview {
  NavigationStack {
    ReminderView()
  }
}
