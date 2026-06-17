//
//  HomeView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
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

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          greetingCard
          lastReadingCard
          sevenDayAverageCard
          miniChartCard
          recentReadingsCard
          reminderCard
          HealthDisclaimerView()
        }
        .padding()
      }
      .background(AppTheme.background)
      .navigationTitle("Blood Pressure Tracker")
    }
  }

  private var greetingCard: some View {
    CardView {
      VStack(alignment: .leading, spacing: 8) {
        Text(greetingText)
          .font(.title2.bold())
        Text("Track and monitor your blood pressure readings.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
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

  @ViewBuilder
  private var lastReadingCard: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Last Reading")
          .font(.headline)

        if let reading = lastReading {
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(reading.systolic)")
              .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("/")
              .font(.title)
              .foregroundStyle(.secondary)
            Text("\(reading.diastolic)")
              .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("mmHg")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          if let pulse = reading.pulse {
            Label("\(pulse) BPM", systemImage: "heart.fill")
              .foregroundStyle(AppTheme.accent)
          }

          StatusBadge(category: reading.category)

          Text(reading.date, format: .dateTime.day().month().year().hour().minute())
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          Text("No readings yet. Tap Add to record your first reading.")
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private var sevenDayAverageCard: some View {
  if let avgSys = sevenDayAverageSystolic, let avgDia = sevenDayAverageDiastolic {
      CardView {
        VStack(alignment: .leading, spacing: 8) {
          Text("7-Day Average")
            .font(.headline)
          Text("\(avgSys)/\(avgDia) mmHg")
            .font(.title3.bold())
          Text("Based on \(sevenDayReadings.count) reading\(sevenDayReadings.count == 1 ? "" : "s")")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  @ViewBuilder
  private var miniChartCard: some View {
    let chartData = Array(readings.prefix(14).reversed())
    if !chartData.isEmpty {
      CardView {
        VStack(alignment: .leading, spacing: 12) {
          Text("Blood Pressure Trend")
            .font(.headline)

          Chart {
            ForEach(chartData, id: \.id) { reading in
              LineMark(
                x: .value("Date", reading.date),
                y: .value("Systolic", reading.systolic)
              )
              .foregroundStyle(AppTheme.accent)
              .interpolationMethod(.catmullRom)

              LineMark(
                x: .value("Date", reading.date),
                y: .value("Diastolic", reading.diastolic)
              )
              .foregroundStyle(AppTheme.secondaryAccent)
              .interpolationMethod(.catmullRom)
            }
          }
          .frame(height: 160)
          .chartYScale(domain: .automatic(includesZero: false))

          HStack(spacing: 16) {
            Label("Systolic", systemImage: "circle.fill")
              .font(.caption)
              .foregroundStyle(AppTheme.accent)
            Label("Diastolic", systemImage: "circle.fill")
              .font(.caption)
              .foregroundStyle(AppTheme.secondaryAccent)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var recentReadingsCard: some View {
    if readings.count > 1 {
      CardView {
        VStack(alignment: .leading, spacing: 12) {
          Text("Recent Readings")
            .font(.headline)

          ForEach(Array(readings.prefix(5))) { reading in
            ReadingRowView(reading: reading)
            if reading.id != readings.prefix(5).last?.id {
              Divider()
            }
          }
        }
      }
    }
  }

  private var reminderCard: some View {
    NavigationLink {
      ReminderView()
    } label: {
      CardView {
        HStack {
          VStack(alignment: .leading, spacing: 6) {
            Text("Reminders")
              .font(.headline)
            Text("Set morning, evening, or custom reminders.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "bell.badge.fill")
            .font(.title2)
            .foregroundStyle(AppTheme.accent)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  HomeView()
    .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
