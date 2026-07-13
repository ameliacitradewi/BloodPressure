//
//  HomeView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \BloodPressureReading.date, order: .reverse)
    private var readings: [BloodPressureReading]
    
    @AppStorage(UserSettings.userNameKey)
    private var userName = ""
    
    private var viewModel: HomeViewModel {
        HomeViewModel(readings: readings, userName: userName)
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
            Text(viewModel.greetingText)
                .font(.subheadline)
                .foregroundStyle(HomePalette.secondaryText)
            
            Text("Blood Pressure Tracker")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(HomePalette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Latest Reading
    @ViewBuilder
    private var latestReadingSection: some View {
        if let reading = viewModel.lastReading {
            LatestReadingDashboardCard(reading: reading, viewModel: viewModel)
        } else {
            EmptyLatestReadingCard()
        }
    }
    
    // MARK: Average
    private var averageSection: some View {
        HStack(spacing: 14) {
            AverageMetricCard(
                title: "Avg Systolic",
                value: viewModel.sevenDayAverageSystolic,
                unit: "mmHg",
                valueColor: HomePalette.systolic
            )
            
            AverageMetricCard(
                title: "Avg Diastolic",
                value: viewModel.sevenDayAverageDiastolic,
                unit: "mmHg",
                valueColor: HomePalette.diastolic
            )
            
            AverageMetricCard(
                title: "Avg Pulse",
                value: viewModel.sevenDayAveragePulse,
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
                    .foregroundStyle(HomePalette.primaryText)

                ForEach(viewModel.recentReadings) { reading in
                    RecentReadingDashboardRow(reading: reading, viewModel: viewModel)
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
                        .foregroundStyle(HomePalette.primaryText)
                    
                    Text("Manage your measurement schedule")
                        .font(.system(.subheadline))
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
    let viewModel: HomeViewModel
    
    private var statusText: String {
        reading.category.rawValue
    }
    
    private var statusPillText: String {
        viewModel.readableCategory(reading.category)
    }
    
    private var statusColor: Color {
        viewModel.categoryColor(for: reading.category)
    }
    
    private var statusProgress: Double {
        viewModel.categoryProgress(for: reading.category)
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
                    .foregroundStyle(Color.white.opacity(0.72))
                
                Text(viewModel.shortDateTime(reading.date))
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.54))
            }
            
            Spacer(minLength: 12)
            
            StatusPill(
                title: statusPillText,
                color: statusColor
            )
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
                .foregroundStyle(HomePalette.pulse)
                .padding(.leading, 8)
        }
    }
    
    private var metadata: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(HomePalette.pulse)
            
            if let pulse = reading.pulse {
                Text(pulse, format: .number)
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("bpm")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            } else {
                Text("-- bpm")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            }
            
            Text("mmHg")
                .font(.system(.subheadline))
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
        .frame(height: 140)
        .padding(.horizontal, 18)
//        .padding(.top, 15)
    }
}

// MARK: Gauge
private struct BloodPressureGauge: View {
    let progress: Double
    let statusText: String
    let statusColor: Color

    private let greenEnd = 0.47
    private let yellowEnd = 0.80

    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var needleAngle: Angle {
        .degrees(180 + normalizedProgress * 180)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let diameter = min(width, proxy.size.height * 1.75)
            let radius = diameter / 2
            let lineWidth = max(diameter * 0.075, 14)
            let needleLength = radius * 0.65
            let arcFrameHeight = radius + lineWidth / 2
            let centerX = width / 2
            let centerY = arcFrameHeight

            ZStack {
                gaugeSegment(
                    from: 0.00,
                    to: greenEnd,
                    color: HomePalette.gaugeGreen,
                    lineWidth: lineWidth
                )

                gaugeSegment(
                    from: greenEnd,
                    to: yellowEnd,
                    color: HomePalette.gaugeYellow,
                    lineWidth: lineWidth
                )

                gaugeSegment(
                    from: yellowEnd,
                    to: 1.00,
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
                    .position(
                        x: centerX,
                        y: centerY
                    )

                Circle()
                    .fill(HomePalette.gaugeNeedle)
                    .frame(
                        width: diameter * 0.085,
                        height: diameter * 0.085
                    )
                    .position(
                        x: centerX,
                        y: centerY
                    )
            }
            .frame(
                width: width,
                height: proxy.size.height
            )
        }
        .animation(
            .easeOut(duration: 0.55),
            value: normalizedProgress
        )
    }

    private func gaugeSegment(
        from start: Double,
        to end: Double,
        color: Color,
        lineWidth: CGFloat
    ) -> some View {
        SemiGaugeSegment(
            startProgress: start,
            endProgress: end
        )
        .stroke(
            color,
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round
            )
        )
    }
}

private struct SemiGaugeSegment: Shape {
    let startProgress: Double
    let endProgress: Double

    func path(in rect: CGRect) -> Path {
        let radius = min(
            rect.width / 2,
            rect.height * 0.72
        )

        let center = CGPoint(
            x: rect.midX,
            y: rect.maxY
        )

        let startAngle = Angle.degrees(
            180 + startProgress * 180
        )

        let endAngle = Angle.degrees(
            180 + endProgress * 180
        )

        var path = Path()

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

// MARK: Status Pill

private struct StatusPill: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(.caption, weight: .semibold))
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
                .foregroundStyle(HomePalette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(value.map(String.init) ?? "--")
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
            
            Text(unit)
                .font(.system(.caption))
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
    let viewModel: HomeViewModel
    
    private var statusColor: Color {
        viewModel.categoryColor(for: reading.category)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(statusColor)
                .frame(width: 11, height: 11)
            
            Text(viewModel.shortDateTime(reading.date))
                .font(.system(.body))
                .foregroundStyle(HomePalette.secondaryText)
                .lineLimit(1)
            
            Spacer(minLength: 10)
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(reading.systolic)")
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(HomePalette.primaryText)
                
                Text("/\(reading.diastolic)")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(HomePalette.primaryText)
                
                Text("mmHg")
                    .font(.system(.caption))
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
                .foregroundStyle(.white)
            
            Text(
                "Capture or add your first blood pressure measurement to start tracking your health."
            )
            .font(.system(.body))
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
        HomeView()
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
