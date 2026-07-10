//
//  HomeView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct HomeView2: View {
    @Query(sort: \BloodPressureReading.date, order: .reverse) private var readings: [BloodPressureReading]
    @AppStorage(UserSettings.userNameKey) private var userName = ""
    
    private var lastReading: BloodPressureReading? {
        readings.first
    }
    
    private var sevenDayReadings: [BloodPressureReading] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return readings.filter { $0.date >= cutoff }
    }
    
    private var sevenDayAverageSystolic: Int? {
        guard !sevenDayReadings.isEmpty else { return nil }
        return sevenDayReadings.map(\.systolic).reduce(0, +) / sevenDayReadings.count
    }
    
    private var sevenDayAverageDiastolic: Int? {
        guard !sevenDayReadings.isEmpty else { return nil }
        return sevenDayReadings.map(\.diastolic).reduce(0, +) / sevenDayReadings.count
    }
    
    private var sevenDayAveragePulse: Int? {
        let pulseValues = sevenDayReadings.compactMap(\.pulse)
        guard !pulseValues.isEmpty else { return nil }
        return pulseValues.reduce(0, +) / pulseValues.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerSection
                    latestReadingSection
                    averageSection
                    recentReadingsSection
                    reminderCard
                    
                    HealthDisclaimerView()
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(HomePalette.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundStyle(HomePalette.secondaryText)
            
            Text("Blood Pressure Tracker")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(HomePalette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        default: timeGreeting = "Good evening"
        }
        
        if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(timeGreeting)!"
        }
        
        return "\(timeGreeting), \(userName)!"
    }
    
    
    // MARK: Latest Reading
    
    @ViewBuilder
    private var latestReadingSection: some View {
        if let reading = lastReading {
            LatestReadingDashboardCard(reading: reading)
        } else {
            EmptyLatestReadingCard()
        }
    }
    
    // MARK: Average
    private var averageSection: some View {
        HStack(spacing: 14) {
            AverageMetricCard(
                title: "Avg Systolic",
                value: sevenDayAverageSystolic,
                unit: "mmHg",
                valueColor: HomePalette.systolic
            )
            
            AverageMetricCard(
                title: "Avg Diastolic",
                value: sevenDayAverageDiastolic,
                unit: "mmHg",
                valueColor: HomePalette.diastolic
            )
            
            AverageMetricCard(
                title: "Avg Pulse",
                value: sevenDayAveragePulse,
                unit: "bpm",
                valueColor: HomePalette.pulse
            )
        }
    }
    
    // MARK: Recent Readings
    
    @ViewBuilder
    private var recentReadingsSection: some View {
        if !readings.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Recent")
                    .font(.system(.title3, weight: .bold))
//                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(HomePalette.primaryText)
                
                ForEach(Array(readings.prefix(5))) { reading in
                    RecentReadingDashboardRow(reading: reading)
                }
            }
        }
    }
    
    // MARK: Reminder
    
    private var reminderCard: some View {
        NavigationLink {
            ReminderView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                    .fill(HomePalette.primaryBlue.opacity(0.10))
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HomePalette.primaryBlue)
                }
                .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminders")
                        .font(.system(.headline, weight: .semibold))
//                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(HomePalette.primaryText)
                    
                    Text("Manage your measurement schedule")
                        .font(.system(.subheadline))
//                        .font(.system(size: 14))
                        .foregroundStyle(HomePalette.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HomePalette.tertiaryText)
            }
            .padding(18)
            .background(
                Color.white,
                in: RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
            .dashboardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: Latest Reading Card

private struct LatestReadingDashboardCard: View {
    let reading: BloodPressureReading
    
    private var statusText: String {
        reading.category.rawValue
//        readableCategory(reading.category)
    }
    
    private var statusPillText: String {
//        reading.category.rawValue
        readableCategory(reading.category)
    }
    
    private var statusColor: Color {
        categoryColor(reading.category)
    }
    
    private var statusProgress: Double {
        categoryProgress(reading.category)
    }
    
    var body: some View {
        ZStack {
            decorativeBackground
            
            VStack(alignment: .leading, spacing: 5) {
                cardHeader
                pressureReading
                metadata
                gauge
            }
            .padding(28)
        }
        .background(
            LinearGradient(
                colors: [
                    HomePalette.heroStart,
                    HomePalette.heroEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.08),
                lineWidth: 1
            )
        }
        .shadow(
            color: HomePalette.heroEnd.opacity(0.18),
            radius: 18,
            x: 0,
            y: 10
        )
    }
    
    private var decorativeBackground: some View {
        GeometryReader { proxy in
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.16),
                            Color.pink.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 230, height: 230)
                .position(
                    x: proxy.size.width + 8,
                    y: 28
                )
        }
        .allowsHitTesting(false)
    }
    
    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Latest Reading")
                    .font(.system(.subheadline, weight: .medium))
//                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                
                Text(shortDateTime(reading.date))
                    .font(.system(.subheadline, weight: .regular))
//                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.54))
            }
            
//            Spacer(minLength: 12)
//            
//            StatusPill(
//                title: statusPillText,
//                color: statusColor
//            )
        }
    }
    
    private var pressureReading: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(reading.systolic)")
                .font(
                    .system(
                        size: 72,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text("/")
                .font(
                    .system(
                        size: 42,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .foregroundStyle(Color.white.opacity(0.46))
            
            Text("\(reading.diastolic)")
                .font(
                    .system(
                        size: 42,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .foregroundStyle(Color.white.opacity(0.58))
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(.headline, weight: .semibold))
//                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(HomePalette.pulse)
                .padding(.leading, 8)
        }
    }
    
    private var metadata: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(.subheadline, weight: .semibold))
//                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HomePalette.pulse)
            
            if let pulse = reading.pulse {
                Text(pulse, format: .number)
                    .font(.system(.headline, weight: .semibold))
//                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("bpm")
                    .font(.system(.subheadline, weight: .semibold))
//                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            } else {
                Text("-- bpm")
                    .font(.system(.headline, weight: .semibold))
//                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            }
            
            Text("mmHg")
                .font(.system(.subheadline))
//                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.38))
                .padding(.leading, 12)
        }
    }
    
    private var gauge: some View {
        BloodPressureGauge(
            progress: statusProgress,
            statusText: statusText,
            statusColor: statusColor
        )
        .frame(height: 205)
        .padding(.horizontal, 18)
        .padding(.top, 15)
    }
}

// MARK: Gauge

private struct BloodPressureGauge: View {
    let progress: Double
    let statusText: String
    let statusColor: Color
    
    private let arcLength = 0.72
    private let startingAngle = 140.0
    
    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }
    
    private var needleAngle: Angle {
        .degrees(
            startingAngle +
            normalizedProgress *
            arcLength *
            360
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            let side = min(
                proxy.size.width,
                proxy.size.height
            )
            
            let lineWidth = max(side * 0.075, 14)
            let needleLength = side * 0.32
            
            ZStack {
                gaugeSegment(
                    from: 0,
                    to: 0.34,
                    color: HomePalette.gaugeGreen,
                    lineWidth: lineWidth
                )
                
                gaugeSegment(
                    from: 0.34,
                    to: 0.58,
                    color: HomePalette.gaugeYellow,
                    lineWidth: lineWidth
                )
                
                gaugeSegment(
                    from: 0.58,
                    to: arcLength,
                    color: HomePalette.gaugeOrange,
                    lineWidth: lineWidth
                )
                
                Capsule()
                    .fill(HomePalette.gaugeNeedle)
                    .frame(
                        width: needleLength,
                        height: 4
                    )
                    .offset(x: needleLength / 2)
                    .rotationEffect(needleAngle)
                
                Circle()
                    .fill(HomePalette.gaugeNeedle)
                    .frame(
                        width: side * 0.085,
                        height: side * 0.085
                    )
                
                Text(statusText)
                    .multilineTextAlignment(.center)
                    .font(.system(.subheadline, weight: .semibold))
//                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .offset(y: side * 0.29)
            }
            .frame(width: side, height: side)
            .position(
                x: proxy.size.width / 2,
                y: proxy.size.height / 2
            )
        }
        .animation(
            .easeOut(duration: 0.55),
            value: normalizedProgress
        )
    }
    
    private func gaugeSegment(
        from start: CGFloat,
        to end: CGFloat,
        color: Color,
        lineWidth: CGFloat
    ) -> some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(startingAngle))
    }
}

// MARK: Status Pill

private struct StatusPill: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(.caption, weight: .semibold))
//            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                color.opacity(0.13),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        color.opacity(0.48),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: Average Card

private struct AverageMetricCard: View {
    let title: String
    let value: Int?
    let unit: String
    let valueColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, weight: .medium))
//                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HomePalette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(value.map(String.init) ?? "--")
                .font(.system(.title, design: .rounded, weight: .semibold))
//                .font(
//                    .system(
//                        size: 29,
//                        weight: .semibold,
//                        design: .rounded
//                    )
//                )
                .foregroundStyle(valueColor)
                .lineLimit(1)
            
            Text(unit)
                .font(.system(.caption))
//                .font(.system(size: 13))
                .foregroundStyle(HomePalette.tertiaryText)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 82,
            alignment: .leading
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .dashboardShadow()
    }
}

// MARK: Recent Reading Row

private struct RecentReadingDashboardRow: View {
    let reading: BloodPressureReading
    
    private var statusColor: Color {
        categoryColor(reading.category)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(statusColor)
                .frame(width: 11, height: 11)
            
            Text(shortDateTime(reading.date))
                .font(.system(.body))
//                .font(.system(size: 16))
                .foregroundStyle(HomePalette.secondaryText)
                .lineLimit(1)
            
            Spacer(minLength: 10)
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(reading.systolic)")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
//                    .font(
//                        .system(
//                            size: 25,
//                            weight: .semibold,
//                            design: .rounded
//                        )
//                    )
                    .foregroundStyle(HomePalette.primaryText)
                
                Text("/\(reading.diastolic)")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
//                    .font(
//                        .system(
//                            size: 22,
//                            weight: .semibold,
//                            design: .rounded
//                        )
//                    )
                    .foregroundStyle(HomePalette.primaryText)
                
                Text("mmHg")
                    .font(.system(.caption))
//                    .font(.system(size: 14))
                    .foregroundStyle(HomePalette.secondaryText)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(
            Color.white,
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .dashboardShadow()
    }
}

// MARK: Empty State

private struct EmptyLatestReadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 58, height: 58)
            
            Text("No readings yet")
                .font(.system(.title2, weight: .bold))
//                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            
            Text(
                "Capture or add your first blood pressure measurement to start tracking your health."
            )
            .font(.system(.body))
//            .font(.system(size: 16))
            .foregroundStyle(Color.white.opacity(0.68))
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background(
            LinearGradient(
                colors: [
                    HomePalette.heroStart,
                    HomePalette.heroEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
    }
}

// MARK: Category Helpers

private func readableCategory(
    _ category: Any
) -> String {
    var result = String(describing: category)
    
    result = result.replacingOccurrences(
        of: "_",
        with: " "
    )
    
    result = result.replacingOccurrences(
        of: "-",
        with: " "
    )
    
    result = result.replacingOccurrences(
        of: "([a-z])([A-Z])",
        with: "$1 $2",
        options: .regularExpression
    )
    
    result = result.replacingOccurrences(
        of: "([A-Za-z])([0-9])",
        with: "$1 $2",
        options: .regularExpression
    )
    
    result = result.replacingOccurrences(
        of: "hypertension",
        with: "High",
        options: .caseInsensitive
    )
    
    return result.capitalized
}

private func categoryColor(
    _ category: Any
) -> Color {
    let rawValue = String(describing: category)
        .lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "_", with: "")
        .replacingOccurrences(of: "-", with: "")
    
    if rawValue.contains("crisis") { return HomePalette.crisis }
    if rawValue.contains("stage2") { return HomePalette.stageTwo }
    if rawValue.contains("stage1") || rawValue.contains("high") { return HomePalette.stageOne }
    if rawValue.contains("elevated") { return HomePalette.elevated }
    if rawValue.contains("normal") { return HomePalette.normal }
    if rawValue.contains("normal") { return HomePalette.low }
    
    return HomePalette.primaryBlue
}

private func categoryProgress(
    _ category: Any
) -> Double {
    let rawValue = String(describing: category)
        .lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "_", with: "")
        .replacingOccurrences(of: "-", with: "")
    
    if rawValue.contains("crisis") { return 0.97 }
    if rawValue.contains("stage2") { return 0.86 }
    if rawValue.contains("stage1") || rawValue.contains("high") { return 0.70 }
    if rawValue.contains("elevated") { return 0.46 }
    if rawValue.contains("normal") { return 0.20 }
    if rawValue.contains("low") || rawValue.contains("hypo") { return 0.01 }
    
    return 0.50
}

// MARK: Date Helper

private func shortDateTime(
    _ date: Date
) -> String {
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

// MARK: Shadow Modifier

private extension View {
    func dashboardShadow() -> some View {
        shadow(
            color: Color.black.opacity(0.055),
            radius: 13,
            x: 0,
            y: 7
        )
    }
}

// MARK: Colors

private enum HomePalette {
    static let background = Color(
        red: 0.955,
        green: 0.965,
        blue: 0.985
    )
    
    static let primaryText = Color(
        red: 0.09,
        green: 0.13,
        blue: 0.25
    )
    
    static let secondaryText = Color(
        red: 0.39,
        green: 0.47,
        blue: 0.63
    )
    
    static let tertiaryText = Color(
        red: 0.68,
        green: 0.73,
        blue: 0.83
    )
    
    static let primaryBlue = Color(
        red: 0.16,
        green: 0.35,
        blue: 0.58
    )
    
    static let heroStart = Color(
        red: 0.16,
        green: 0.35,
        blue: 0.57
    )
    
    static let heroEnd = Color(
        red: 0.10,
        green: 0.22,
        blue: 0.40
    )
    
    static let systolic = Color(
        red: 0.15,
        green: 0.32,
        blue: 0.56
    )
    
    static let diastolic = Color(
        red: 0.48,
        green: 0.30,
        blue: 0.90
    )
    
    static let pulse = Color(
        red: 0.96,
        green: 0.23,
        blue: 0.43
    )
    
    static let normal = Color(
        red: 0.20,
        green: 0.66,
        blue: 0.43
    )
    
    static let elevated = Color(
        red: 0.91,
        green: 0.66,
        blue: 0.12
    )
    
    static let stageOne = Color(
        red: 0.97,
        green: 0.39,
        blue: 0.05
    )
    
    static let stageTwo = Color(
        red: 0.91,
        green: 0.20,
        blue: 0.20
    )
    
    static let crisis = Color(
        red: 0.72,
        green: 0.18,
        blue: 0.40
    )
    
    static let low = Color(
        red: 0.6,
        green: 0.74,
        blue: 0.86
    )
    
    static let gaugeGreen = Color(
        red: 0.18,
        green: 0.67,
        blue: 0.43
    )
    
    static let gaugeYellow = Color(
        red: 0.91,
        green: 0.65,
        blue: 0.12
    )
    
    static let gaugeOrange = Color(
        red: 0.95,
        green: 0.34,
        blue: 0.07
    )
    
    static let gaugeNeedle = Color(
        red: 0.06,
        green: 0.13,
        blue: 0.27
    )
}

//#Preview {
//    HomeView2()
//        .modelContainer(for: BloodPressureReading.self, inMemory: true)
//}


#Preview("Home - With Mock Data") {
    HomeView2Preview()
}

@MainActor
private struct HomeView2Preview: View {
    var body: some View {
        HomeView2()
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

        func mockDate(daysAgo: Int, hour: Int, minute: Int) -> Date {
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
                systolic: 204,
                diastolic: 80,
                pulse: 80,
                date: mockDate(daysAgo: 0, hour: 8, minute: 45),
                notes: "Morning reading",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 211,
                diastolic: 80,
                pulse: 74,
                date: mockDate(daysAgo: 1, hour: 7, minute: 30),
                notes: "After breakfast",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 205,
                diastolic: 84,
                pulse: 79,
                date: mockDate(daysAgo: 2, hour: 8, minute: 10),
                notes: "Normal activity",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 208,
                diastolic: 81,
                pulse: 75,
                date: mockDate(daysAgo: 4, hour: 7, minute: 45),
                notes: "Morning check",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            ),
            BloodPressureReading(
                systolic: 160,
                diastolic: 76,
                pulse: 72,
                date: mockDate(daysAgo: 6, hour: 8, minute: 0),
                notes: "Relaxed condition",
                position: MeasurementPosition.sitting.rawValue,
                arm: ArmUsed.leftArm.rawValue
            )
        ]
    }
}
