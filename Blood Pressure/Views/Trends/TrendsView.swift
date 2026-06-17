//
//  TrendsView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData
import Charts

enum TrendTimeFilter: String, CaseIterable, Identifiable {
  case sevenDays = "7 Days"
  case thirtyDays = "30 Days"
  case threeMonths = "3 Months"
  case oneYear = "1 Year"

  var id: String { rawValue }

  var startDate: Date {
    let calendar = Calendar.current
    switch self {
    case .sevenDays:
      return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    case .thirtyDays:
      return calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    case .threeMonths:
      return calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    case .oneYear:
      return calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    }
  }
}

struct TrendsView: View {
  @Query(sort: \BloodPressureReading.date, order: .forward) private var allReadings: [BloodPressureReading]
  @State private var selectedFilter: TrendTimeFilter = .sevenDays
  @State private var showPulseChart = true

  private var filteredReadings: [BloodPressureReading] {
    allReadings.filter { $0.date >= selectedFilter.startDate }
  }

  private var averageSystolic: Int? {
    guard !filteredReadings.isEmpty else { return nil }
    return filteredReadings.map(\.systolic).reduce(0, +) / filteredReadings.count
  }

  private var averageDiastolic: Int? {
    guard !filteredReadings.isEmpty else { return nil }
    return filteredReadings.map(\.diastolic).reduce(0, +) / filteredReadings.count
  }

  private var highestReading: BloodPressureReading? {
    filteredReadings.max { $0.systolic < $1.systolic }
  }

  private var lowestReading: BloodPressureReading? {
    filteredReadings.min { $0.systolic < $1.systolic }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          filterPicker

          if filteredReadings.isEmpty {
            ContentUnavailableView(
              "No Data",
              systemImage: "chart.line.uptrend.xyaxis",
              description: Text("Add readings to see trends for this period.")
            )
            .padding(.top, 40)
          } else {
            bpChartCard
            if showPulseChart && filteredReadings.contains(where: { $0.pulse != nil }) {
              pulseChartCard
            }
            statisticsCard
            insightCard
          }
        }
        .padding()
      }
      .background(AppTheme.background)
      .navigationTitle("Trends")
    }
  }

  private var filterPicker: some View {
    Picker("Time Range", selection: $selectedFilter) {
      ForEach(TrendTimeFilter.allCases) { filter in
        Text(filter.rawValue).tag(filter)
      }
    }
    .pickerStyle(.segmented)
  }

  private var bpChartCard: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Blood Pressure")
          .font(.headline)

        Chart {
          ForEach(filteredReadings) { reading in
            LineMark(
              x: .value("Date", reading.date),
              y: .value("Systolic", reading.systolic)
            )
            .foregroundStyle(by: .value("Type", "Systolic"))
            .interpolationMethod(.catmullRom)

            LineMark(
              x: .value("Date", reading.date),
              y: .value("Diastolic", reading.diastolic)
            )
            .foregroundStyle(by: .value("Type", "Diastolic"))
            .interpolationMethod(.catmullRom)
          }
        }
        .frame(height: 220)
        .chartForegroundStyleScale([
          "Systolic": AppTheme.accent,
          "Diastolic": AppTheme.secondaryAccent
        ])
        .chartYScale(domain: .automatic(includesZero: false))
      }
    }
  }

  private var pulseChartCard: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        Toggle("Show Pulse Chart", isOn: $showPulseChart)
          .font(.headline)

        Chart {
          ForEach(filteredReadings.filter { $0.pulse != nil }) { reading in
            LineMark(
              x: .value("Date", reading.date),
              y: .value("Pulse", reading.pulse ?? 0)
            )
            .foregroundStyle(.pink)
            .interpolationMethod(.catmullRom)
          }
        }
        .frame(height: 160)
        .chartYScale(domain: .automatic(includesZero: false))
      }
    }
  }

  private var statisticsCard: some View {
    CardView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Statistics")
          .font(.headline)

        if let avgSys = averageSystolic, let avgDia = averageDiastolic {
          LabeledContent("Average Systolic", value: "\(avgSys) mmHg")
          LabeledContent("Average Diastolic", value: "\(avgDia) mmHg")
        }

        if let highest = highestReading {
          LabeledContent("Highest Reading", value: "\(highest.systolic)/\(highest.diastolic)")
        }

        if let lowest = lowestReading {
          LabeledContent("Lowest Reading", value: "\(lowest.systolic)/\(lowest.diastolic)")
        }
      }
    }
  }

  private var insightCard: some View {
    CardView {
      VStack(alignment: .leading, spacing: 8) {
        Label("Insight", systemImage: "lightbulb.fill")
          .font(.headline)
          .foregroundStyle(.yellow)

        Text(TrendInsights.generate(for: filteredReadings))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  TrendsView()
    .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
