//
//  HistoryView.swift
//  Blood Pressure
//

//
//  HistoryView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct HistoryView2: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BloodPressureReading.date, order: .reverse)
    private var readings: [BloodPressureReading]

    @State private var selectedMode: HistoryMode = .list
    @State private var expandedMonthIDs: Set<String> = []

    enum HistoryMode: String, CaseIterable, Identifiable {
        case chart = "Chart"
        case list = "List"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.96, blue: 0.98)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        
                        historyModePicker
                        
                        if readings.isEmpty {
                            emptyState
                        } else {
                            if selectedMode == .chart {
                                chartPlaceholder
                            } else {
                                listSection
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                expandLatestMonthIfNeeded()
            }
            .onChange(of: readings.count) { _, _ in
                expandLatestMonthIfNeeded()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("History")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))

            Text("\(readings.count) \(readings.count == 1 ? "reading" : "readings") logged")
                .font(.system(.body, weight: .regular))
                .foregroundStyle(Color(red: 0.42, green: 0.48, blue: 0.62))
        }
    }

    private var historyModePicker: some View {
        HStack(spacing: 4) {
            ForEach(HistoryMode.allCases) { mode in
                Button {
                    withAnimation(.snappy) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode == .list ? "list.bullet" : "chart.bar" )
                            .font(.system(.subheadline, weight: .semibold))
                        
                        Text(mode.rawValue)
                            .font(.system(.subheadline, weight: .semibold))
                    }
                    .foregroundStyle(selectedMode == mode ? Color(red: 0.12, green: 0.30, blue: 0.53) : Color(red: 0.45, green: 0.52, blue: 0.64))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        if selectedMode == mode {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.90, green: 0.93, blue: 0.97))
        )
    }

    private var chartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(Color(red: 0.42, green: 0.48, blue: 0.62))

            Text("Chart view")
                .font(.headline)
                .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))

            Text("We will style this section next.")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.42, green: 0.48, blue: 0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
    }

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(monthGroups) { monthGroup in
                VStack(alignment: .leading, spacing: 14) {
                    monthHeader(monthGroup)

                    if expandedMonthIDs.contains(monthGroup.id) {
                        VStack(spacing: 14) {
                            ForEach(monthGroup.dayGroups) { dayGroup in
                                dayCard(dayGroup)
                            }
                        }
                    }
                }
            }
        }
    }

    private func monthHeader(_ monthGroup: MonthHistoryGroup) -> some View {
        Button {
            withAnimation(.snappy) {
                toggleMonth(monthGroup.id)
            }
        } label: {
            HStack(spacing: 10) {
                Text(monthGroup.title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))

                Spacer()

                Text("\(monthGroup.readingsCount) \(monthGroup.readingsCount == 1 ? "reading" : "readings")")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Color(red: 0.68, green: 0.74, blue: 0.84))

                Image(
                    systemName: expandedMonthIDs.contains(monthGroup.id)
                    ? "chevron.down"
                    : "chevron.right"
                )
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(Color(red: 0.68, green: 0.74, blue: 0.84))
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }

    private func dayCard(_ dayGroup: DayHistoryGroup) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(dayGroup.title)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(Color(red: 0.12, green: 0.30, blue: 0.53))

                Spacer()

                Text("\(dayGroup.readings.count) \(dayGroup.readings.count == 1 ? "entry" : "entries")")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Color(red: 0.68, green: 0.74, blue: 0.84))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)

            Divider()
                .background(Color(red: 0.88, green: 0.91, blue: 0.95))

            readingTableHeader

            Divider()
                .background(Color(red: 0.88, green: 0.91, blue: 0.95))

            ForEach(dayGroup.readings) { reading in
                NavigationLink {
                    ReadingDetailView(reading: reading)
                } label: {
                    readingRow(reading)
                }
                .buttonStyle(.plain)

                if reading.id != dayGroup.readings.last?.id {
                    Divider()
                        .padding(.leading, 22)
                        .background(Color(red: 0.88, green: 0.91, blue: 0.95))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        )
    }

    private var readingTableHeader: some View {
        HStack {
            Text("")
                .frame(width: 86, alignment: .leading)

            Text("SYS")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(Color(red: 0.12, green: 0.30, blue: 0.53))
                .frame(maxWidth: .infinity)

            Text("DIA")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(Color(red: 0.52, green: 0.34, blue: 0.88))
                .frame(maxWidth: .infinity)

            Text("Pulse")
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(Color(red: 0.92, green: 0.20, blue: 0.42))
                .frame(maxWidth: .infinity)

            Text("")
                .frame(width: 28)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(Color(red: 0.97, green: 0.98, blue: 1.00))
    }

    private func readingRow(_ reading: BloodPressureReading) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(reading.category.color)
                    .frame(width: 8, height: 8)

                Text(Self.timeFormatter.string(from: reading.date))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Color(red: 0.42, green: 0.48, blue: 0.62))
                    .monospacedDigit()
            }
            .frame(width: 86, alignment: .leading)

            Text("\(reading.systolic)")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Color(red: 0.12, green: 0.30, blue: 0.53))
                .frame(maxWidth: .infinity)

            Text("\(reading.diastolic)")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Color(red: 0.52, green: 0.34, blue: 0.88))
                .frame(maxWidth: .infinity)

            Text(reading.pulse.map { "\($0)" } ?? "—")
                .font(.system(.title2, weight: .bold))
                .foregroundStyle(Color(red: 0.92, green: 0.20, blue: 0.42))
                .frame(maxWidth: .infinity)

            Image(systemName: "chevron.right")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(Color(red: 0.68, green: 0.74, blue: 0.84))
                .frame(width: 28)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Readings Yet",
            systemImage: "heart.text.square",
            description: Text("Your blood pressure history will appear here.")
        )
    }

    private var monthGroups: [MonthHistoryGroup] {
        let calendar = Calendar.current

        let groupedByMonth = Dictionary(grouping: readings) { reading in
            startOfMonth(for: reading.date, calendar: calendar)
        }

        return groupedByMonth
            .map { monthDate, monthReadings in
                let groupedByDay = Dictionary(grouping: monthReadings) { reading in
                    calendar.startOfDay(for: reading.date)
                }

                let dayGroups = groupedByDay
                    .map { dayDate, dayReadings in
                        DayHistoryGroup(
                            id: "\(dayDate.timeIntervalSince1970)",
                            date: dayDate,
                            title: Self.dayFormatter.string(from: dayDate),
                            readings: dayReadings.sorted { $0.date > $1.date }
                        )
                    }
                    .sorted { $0.date > $1.date }

                return MonthHistoryGroup(
                    id: monthID(for: monthDate, calendar: calendar),
                    date: monthDate,
                    title: Self.monthFormatter.string(from: monthDate),
                    readingsCount: monthReadings.count,
                    dayGroups: dayGroups
                )
            }
            .sorted { $0.date > $1.date }
    }

    private func toggleMonth(_ id: String) {
        if expandedMonthIDs.contains(id) {
            expandedMonthIDs.remove(id)
        } else {
            expandedMonthIDs.insert(id)
        }
    }

    private func expandLatestMonthIfNeeded() {
        guard expandedMonthIDs.isEmpty,
              let latestMonthID = monthGroups.first?.id else {
            return
        }

        expandedMonthIDs.insert(latestMonthID)
    }

    private func startOfMonth(
        for date: Date,
        calendar: Calendar
    ) -> Date {
        let components = calendar.dateComponents(
            [.year, .month],
            from: date
        )

        return calendar.date(from: components) ?? date
    }

    private func monthID(
        for date: Date,
        calendar: Calendar
    ) -> String {
        let components = calendar.dateComponents(
            [.year, .month],
            from: date
        )

        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }

    private func deleteReadings(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(readings[index])
        }
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

private struct MonthHistoryGroup: Identifiable {
    let id: String
    let date: Date
    let title: String
    let readingsCount: Int
    let dayGroups: [DayHistoryGroup]
}

private struct DayHistoryGroup: Identifiable {
    let id: String
    let date: Date
    let title: String
    let readings: [BloodPressureReading]
}

#Preview {
    HistoryView2()
        .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
