//
//  TrendsView.swift
//  Blood Pressure
//

//
//  TrendsView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData
import Charts

enum TrendTimeFilter: String, CaseIterable, Identifiable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case threeMonths = "3M"
    case oneYear = "1Y"
    case all = "All"

    var id: String { rawValue }

    var startDate: Date? {
        let calendar = Calendar.current

        switch self {
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: Date())
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: Date())
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: Date())
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: Date())
        case .all:
            return nil
        }
    }
}

struct TrendsView: View {
    @Query(sort: \BloodPressureReading.date, order: .forward)
    private var allReadings: [BloodPressureReading]

    @State private var selectedFilter: TrendTimeFilter = .thirtyDays
    @State private var selectedReading: BloodPressureReading?

    private var filteredReadings: [BloodPressureReading] {
        guard let startDate = selectedFilter.startDate else {
            return allReadings
        }

        return allReadings.filter { reading in
            reading.date >= startDate
        }
    }

    private var averageSystolic: Int? {
        guard !filteredReadings.isEmpty else {
            return nil
        }

        return filteredReadings.map(\.systolic).reduce(0, +) / filteredReadings.count
    }

    private var averageDiastolic: Int? {
        guard !filteredReadings.isEmpty else {
            return nil
        }

        return filteredReadings.map(\.diastolic).reduce(0, +) / filteredReadings.count
    }

    private var averagePulse: Int? {
        let pulseValues = filteredReadings.compactMap(\.pulse)

        guard !pulseValues.isEmpty else {
            return nil
        }

        return pulseValues.reduce(0, +) / pulseValues.count
    }

    private var chartYDomain: ClosedRange<Int> {
        let pulseValues = filteredReadings.compactMap(\.pulse)

        let values = filteredReadings.flatMap { reading in
            [
                reading.systolic,
                reading.diastolic
            ]
        } + pulseValues

        guard let minValue = values.min(),
              let maxValue = values.max() else {
            return 30...150
        }

        let lowerBound = min(
            30,
            ((minValue - 10) / 10) * 10
        )

        let upperBound = max(
            150,
            ((maxValue + 20) / 10) * 10
        )

        return lowerBound...upperBound
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomePalette.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection

                        filterSection

                        if filteredReadings.isEmpty {
                            emptyState
                        } else {
                            chartCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: selectedFilter) { _, _ in
                selectedReading = nil
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Trends")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(HomePalette.primaryText)

            Text("\(filteredReadings.count) \(filteredReadings.count == 1 ? "reading" : "readings") logged")
                .font(.system(.body, weight: .regular))
                .foregroundStyle(HomePalette.secondaryText)
        }
    }

    private var filterSection: some View {
        HStack {
            ForEach(TrendTimeFilter.allCases) { filter in
                Button {
                    withAnimation(.snappy) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(
                            selectedFilter == filter
                            ? .white
                            : HomePalette.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 35)
                        .background(
                            Capsule()
                                .fill(
                                    selectedFilter == filter
                                    ? HomePalette.primaryBlue
                                    : Color(red: 0.90, green: 0.93, blue: 0.97)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chartCard: some View {
        VStack(spacing: 24) {
            averageCards
            chartSection

            Text("Yellow dashed = normal thresholds (120/80 mmHg)")
                .font(.system(.footnote, weight: .regular))
                .foregroundStyle(HomePalette.tertiaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.055),
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    private var averageCards: some View {
        HStack(spacing: 14) {
            AverageMetricCard(
                title: "Avg Systolic",
                value: averageSystolic,
                unit: "mmHg",
                valueColor: HomePalette.systolic
            )

            AverageMetricCard(
                title: "Avg Diastolic",
                value: averageDiastolic,
                unit: "mmHg",
                valueColor: HomePalette.diastolic
            )

            AverageMetricCard(
                title: "Avg Pulse",
                value: averagePulse,
                unit: "bpm",
                valueColor: HomePalette.pulse
            )
        }
    }

    private var chartSection: some View {
        Chart {
            RuleMark(y: .value("Systolic threshold", 120))
                .foregroundStyle(Color.yellow)
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 1.5,
                        dash: [7, 6]
                    )
                )

            RuleMark(y: .value("Diastolic threshold", 80))
                .foregroundStyle(Color.yellow)
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 1.5,
                        dash: [7, 6]
                    )
                )

            ForEach(filteredReadings) { reading in
                LineMark(
                    x: .value("Date", reading.date),
                    y: .value("Value", reading.systolic)
                )
                .foregroundStyle(by: .value("Metric", "Systolic"))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", reading.date),
                    y: .value("Value", reading.systolic)
                )
                .foregroundStyle(by: .value("Metric", "Systolic"))
                .symbolSize(42)

                LineMark(
                    x: .value("Date", reading.date),
                    y: .value("Value", reading.diastolic)
                )
                .foregroundStyle(by: .value("Metric", "Diastolic"))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", reading.date),
                    y: .value("Value", reading.diastolic)
                )
                .foregroundStyle(by: .value("Metric", "Diastolic"))
                .symbolSize(42)

                if let pulse = reading.pulse {
                    LineMark(
                        x: .value("Date", reading.date),
                        y: .value("Value", pulse)
                    )
                    .foregroundStyle(by: .value("Metric", "Pulse"))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", reading.date),
                        y: .value("Value", pulse)
                    )
                    .foregroundStyle(by: .value("Metric", "Pulse"))
                    .symbolSize(42)
                }
            }

            if let selectedReading {
                RuleMark(
                    x: .value("Selected Date", selectedReading.date)
                )
                .foregroundStyle(HomePalette.tertiaryText.opacity(0.55))
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 1,
                        dash: [5, 5]
                    )
                )

                PointMark(
                    x: .value("Selected Date", selectedReading.date),
                    y: .value("Selected Systolic", selectedReading.systolic)
                )
                .foregroundStyle(HomePalette.systolic)
                .symbolSize(70)
                .annotation(
                    position: .top,
                    alignment: .center,
                    spacing: 10
                ) {
                    selectedReadingTooltip(selectedReading)
                }
            }
        }
        .chartYScale(domain: chartYDomain)
        .chartForegroundStyleScale([
            "Systolic": HomePalette.systolic,
            "Diastolic": HomePalette.diastolic,
            "Pulse": HomePalette.pulse
        ])
        .chartLegend(position: .bottom, alignment: .center, spacing: 15)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine()
                    .foregroundStyle(HomePalette.tertiaryText.opacity(0.18))

                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(HomePalette.tertiaryText)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 30)) { value in
                AxisGridLine()
                    .foregroundStyle(HomePalette.tertiaryText.opacity(0.18))

                AxisValueLabel()
                    .foregroundStyle(HomePalette.tertiaryText)
            }
        }
        .chartOverlay { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelectedReading(
                                    from: value.location,
                                    chartProxy: chartProxy,
                                    geometry: geometry
                                )
                            }
                    )
            }
        }
        .frame(height: 310)
    }

    private func selectedReadingTooltip(
        _ reading: BloodPressureReading
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Self.tooltipDateFormatter.string(from: reading.date))
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(HomePalette.primaryText)

            Text("Systolic : \(reading.systolic) mmHg")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(HomePalette.systolic)

            Text("Diastolic : \(reading.diastolic) mmHg")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(HomePalette.diastolic)

            Text("Pulse : \(reading.pulse.map(String.init) ?? "—") bpm")
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(HomePalette.pulse)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.10),
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(HomePalette.tertiaryText)

            Text("No Data")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(HomePalette.primaryText)

            Text("Add readings to see trends for this period.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(HomePalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .shadow(
                    color: .black.opacity(0.055),
                    radius: 14,
                    x: 0,
                    y: 7
                )
        )
    }

    private func updateSelectedReading(
        from location: CGPoint,
        chartProxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard let plotFrame = chartProxy.plotFrame else {
            return
        }

        let plotAreaFrame = geometry[plotFrame]
        let xPosition = location.x - plotAreaFrame.origin.x

        guard let selectedDate: Date = chartProxy.value(atX: xPosition) else {
            return
        }

        selectedReading = nearestReading(
            to: selectedDate
        )
    }

    private func nearestReading(
        to date: Date
    ) -> BloodPressureReading? {
        filteredReadings.min { first, second in
            abs(first.date.timeIntervalSince(date)) < abs(second.date.timeIntervalSince(date))
        }
    }

    private static let tooltipDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

//#Preview {
//    TrendsView()
//        .modelContainer(for: BloodPressureReading.self, inMemory: true)
//}

#Preview("Trends - With Data") {
    TrendsViewWithDataPreview()
}

#Preview("Trends - Empty") {
    TrendsView()
        .modelContainer(for: BloodPressureReading.self, inMemory: true)
}

@MainActor
private struct TrendsViewWithDataPreview: View {
    var body: some View {
        TrendsView()
            .modelContainer(Self.previewContainer)
    }

    private static let previewContainer: ModelContainer = {
        do {
            let schema = Schema([
                BloodPressureReading.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            let context = container.mainContext

            Self.mockReadings.forEach { reading in
                context.insert(reading)
            }

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    private static var mockReadings: [BloodPressureReading] {
        let calendar = Calendar.current
        let now = Date()

        func mockDate(
            daysAgo: Int,
            hour: Int,
            minute: Int
        ) -> Date {
            let targetDate = calendar.date(
                byAdding: .day,
                value: -daysAgo,
                to: now
            ) ?? now

            return calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: targetDate
            ) ?? targetDate
        }

        return [
            BloodPressureReading(
                systolic: 122,
                diastolic: 78,
                pulse: 72,
                date: mockDate(daysAgo: 9, hour: 7, minute: 30),
                notes: "Morning reading",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 126,
                diastolic: 82,
                pulse: 74,
                date: mockDate(daysAgo: 8, hour: 7, minute: 45),
                notes: "After breakfast",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 132,
                diastolic: 86,
                pulse: 78,
                date: mockDate(daysAgo: 7, hour: 8, minute: 10),
                notes: "Slightly stressed",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 128,
                diastolic: 83,
                pulse: 75,
                date: mockDate(daysAgo: 6, hour: 8, minute: 0),
                notes: "Normal activity",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 124,
                diastolic: 80,
                pulse: 73,
                date: mockDate(daysAgo: 5, hour: 7, minute: 50),
                notes: "Morning check",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 118,
                diastolic: 77,
                pulse: 70,
                date: mockDate(daysAgo: 4, hour: 8, minute: 20),
                notes: "Relaxed",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 70,
                diastolic: 40,
                pulse: 66,
                date: mockDate(daysAgo: 3, hour: 14, minute: 24),
                notes: "Low reading test",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 119,
                diastolic: 77,
                pulse: 66,
                date: mockDate(daysAgo: 2, hour: 15, minute: 27),
                notes: "Afternoon reading",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 124,
                diastolic: 81,
                pulse: 72,
                date: mockDate(daysAgo: 1, hour: 15, minute: 28),
                notes: "Latest reading",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            )
        ]
    }
}
