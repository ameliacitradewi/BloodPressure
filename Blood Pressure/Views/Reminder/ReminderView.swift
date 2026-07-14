//
//  ReminderView.swift
//  Blood Pressure
//

import SwiftUI
import UserNotifications

struct ReminderView: View {
    @StateObject private var notificationService = NotificationService()

    @AppStorage("bp_reminders_json")
    private var remindersJSON = ""

    @State private var reminders: [ReminderNotification] = []

    @State private var showPermissionDenied = false
    @State private var showAddReminderForm = false
    @State private var showMaxReminderAlert = false

    @State private var newReminderTime = Self.defaultTime(hour: 8)
    @State private var newReminderTitle = ""
    @State private var validationError: String?

    private let maxReminderCount = 10
    private let maxTitleLength = 23

    private var canAddMoreReminders: Bool {
        reminders.count < maxReminderCount
    }

    private var canSubmitNewReminder: Bool {
        !newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        canAddMoreReminders
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomePalette.background
                    .ignoresSafeArea()

                List {
                    headerSection
                        .listRowStyle()

                    if showPermissionDenied ||
                        notificationService.authorizationStatus == .denied {
                        PermissionDeniedView(
                            title: "Notifications Disabled",
                            message: "Please enable notifications in Settings to receive blood pressure reminders.",
                            systemImage: "bell.slash.fill"
                        )
                        .listRowStyle()
                    }

                    ForEach(reminders) { reminder in
                        reminderRow(reminder)
                            .listRowStyle()
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteReminder(reminder)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }

                    if showAddReminderForm {
                        addReminderForm
                            .listRowStyle()
                    } else {
                        addReminderButton
                            .listRowStyle()
                    }

                    infoCard
                        .listRowStyle()
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(HomePalette.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                loadReminders()
                await notificationService.refreshAuthorizationStatus()
                showPermissionDenied = notificationService.authorizationStatus == .denied
            }
            .alert("Maximum Reminders", isPresented: $showMaxReminderAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can only create up to 10 reminders.")
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reminders")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(HomePalette.primaryText)

            Text("Daily notifications to log your BP")
                .font(.system(.body, weight: .regular))
                .foregroundStyle(HomePalette.secondaryText)
        }
    }

    private func reminderRow(
        _ reminder: ReminderNotification
    ) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(HomePalette.primaryBlue.opacity(0.10))

                Image(systemName: "bell")
                    .font(.system(.title3, weight: .regular))
                    .foregroundStyle(HomePalette.primaryBlue)
            }
            .frame(width: 45, height: 45)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Self.timeFormatter.string(from: reminder.time))
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .foregroundStyle(HomePalette.primaryText)

                    Text(Self.periodFormatter.string(from: reminder.time))
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(HomePalette.primaryText)
                }

                Text(reminder.title)
                    .font(.system(.body, weight: .regular))
                    .foregroundStyle(HomePalette.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Toggle(
                "",
                isOn: isReminderEnabledBinding(for: reminder)
            )
            .labelsHidden()
            .tint(HomePalette.primaryBlue)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.055),
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    private var addReminderButton: some View {
        Button {
            guard canAddMoreReminders else {
                showMaxReminderAlert = true
                return
            }

            withAnimation(.snappy) {
                showAddReminderForm = true
                validationError = nil
                newReminderTitle = ""
                newReminderTime = Self.defaultTime(hour: 8)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(.headline, weight: .semibold))

                Text("Add Reminder")
                    .font(.system(.headline, weight: .bold))
            }
            .foregroundStyle(HomePalette.primaryBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        HomePalette.tertiaryText.opacity(0.65),
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [
                                6,
                                5
                            ]
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var addReminderForm: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("New Reminder")
                .font(.system(.headline, weight: .semibold))
                .foregroundStyle(HomePalette.primaryText)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Time")
                        .font(.system(.body, weight: .regular))
                        .foregroundStyle(HomePalette.secondaryText)
                    
                    Spacer()

                    DatePicker(
                        "",
                        selection: $newReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(HomePalette.primaryBlue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .frame(height: 66)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(HomePalette.background.opacity(0.70))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(HomePalette.tertiaryText.opacity(0.35), lineWidth: 1)
                        }
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Label")
                        .font(.system(.body, weight: .regular))
                        .foregroundStyle(HomePalette.secondaryText)

                    Spacer()

                    Text("\(newReminderTitle.count)/\(maxTitleLength)")
                        .font(.caption)
                        .foregroundStyle(HomePalette.tertiaryText)
                }

                TextField(
                    "Morning check",
                    text: $newReminderTitle
                )
                .font(.system(.body, weight: .regular))
                .foregroundStyle(HomePalette.primaryText)
                .padding(.horizontal, 20)
                .frame(height: 66)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(HomePalette.background.opacity(0.70))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(HomePalette.tertiaryText.opacity(0.35), lineWidth: 1)
                        }
                )
                .onChange(of: newReminderTitle) { _, newValue in
                    let sanitized = sanitizedTitle(from: newValue)

                    if sanitized != newValue {
                        newReminderTitle = sanitized
                    }
                }

                if let validationError {
                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) {
                        cancelAddReminder()
                    }
                } label: {
                    Text("Cancel")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(HomePalette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            Capsule()
                                .fill(HomePalette.background)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    addReminder()
                } label: {
                    Text("Add")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            Capsule()
                                .fill(
                                    canSubmitNewReminder
                                    ? HomePalette.primaryBlue
                                    : HomePalette.tertiaryText.opacity(0.45)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmitNewReminder)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.055),
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "bell")
                .font(.system(.headline, weight: .medium))
                .foregroundStyle(HomePalette.primaryBlue)
                .padding(.top, 2)

            Text("Reminders help you build a consistent tracking habit. For accurate results, measure at the same time each day, after 5 minutes of rest.")
                .font(.system(.caption, weight: .regular))
                .foregroundStyle(HomePalette.primaryBlue)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(HomePalette.primaryBlue.opacity(0.08))
        )
    }

    private func isReminderEnabledBinding(
        for reminder: ReminderNotification
    ) -> Binding<Bool> {
        Binding {
            reminders.first(where: { $0.id == reminder.id })?.isEnabled ?? false
        } set: { newValue in
            guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else {
                return
            }

            reminders[index].isEnabled = newValue

            Task {
                await saveAndScheduleReminders()
            }
        }
    }

    private func addReminder() {
        guard canAddMoreReminders else {
            showMaxReminderAlert = true
            return
        }

        let title = sanitizedTitle(from: newReminderTitle)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            validationError = "Please enter a reminder label."
            return
        }

        validationError = nil

        let reminder = ReminderNotification(
            title: title,
            time: newReminderTime,
            isEnabled: true
        )

        reminders.append(reminder)

        withAnimation(.snappy) {
            showAddReminderForm = false
            newReminderTitle = ""
            newReminderTime = Self.defaultTime(hour: 8)
        }

        Task {
            await saveAndScheduleReminders()
        }
    }

    private func cancelAddReminder() {
        showAddReminderForm = false
        validationError = nil
        newReminderTitle = ""
        newReminderTime = Self.defaultTime(hour: 8)
    }

    private func deleteReminder(
        _ reminder: ReminderNotification
    ) {
        reminders.removeAll { item in
            item.id == reminder.id
        }

        Task {
            await saveAndScheduleReminders()
        }
    }

    private func saveAndScheduleReminders() async {
        saveReminders()

        let needsPermission = reminders.contains { reminder in
            reminder.isEnabled
        }

        if needsPermission && notificationService.authorizationStatus == .notDetermined {
            let granted = await notificationService.requestPermission()

            if !granted {
                disableAllReminders()
                showPermissionDenied = true
                saveReminders()
                await notificationService.scheduleReminders(reminders)
                return
            }
        }

        if notificationService.authorizationStatus == .denied {
            disableAllReminders()
            showPermissionDenied = true
            saveReminders()
            await notificationService.scheduleReminders(reminders)
            return
        }

        showPermissionDenied = false

        await notificationService.scheduleReminders(reminders)
    }

    private func disableAllReminders() {
        reminders = reminders.map { reminder in
            var updatedReminder = reminder
            updatedReminder.isEnabled = false
            return updatedReminder
        }
    }

    private func loadReminders() {
        guard let data = remindersJSON.data(using: .utf8),
              let decodedReminders = try? JSONDecoder().decode(
                [ReminderNotification].self,
                from: data
              )
        else {
            reminders = Self.defaultReminders
            saveReminders()
            return
        }

        reminders = decodedReminders
    }

    private func saveReminders() {
        guard let data = try? JSONEncoder().encode(reminders),
              let encodedString = String(data: data, encoding: .utf8)
        else {
            return
        }

        remindersJSON = encodedString
    }

    private func sanitizedTitle(
        from value: String
    ) -> String {
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)

        let filtered = value.unicodeScalars.filter { scalar in
            allowedCharacters.contains(scalar)
        }

        let joined = String(String.UnicodeScalarView(filtered))

        let normalized = joined.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        return String(normalized.prefix(maxTitleLength))
    }

    private static var defaultReminders: [ReminderNotification] {
        [
            ReminderNotification(
                title: "Morning check",
                time: defaultTime(hour: 8),
                isEnabled: false
            ),
            ReminderNotification(
                title: "Evening check",
                time: defaultTime(hour: 20),
                isEnabled: false
            )
        ]
    }

    private static func defaultTime(
        hour: Int,
        minute: Int = 0
    ) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()

    private static let periodFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter
    }()
}

private extension View {
    func listRowStyle() -> some View {
        self
            .listRowInsets(
                EdgeInsets(
                    top: 8,
                    leading: 20,
                    bottom: 8,
                    trailing: 20
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

#Preview {
    ReminderView()
}
