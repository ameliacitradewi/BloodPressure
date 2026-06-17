//
//  HistoryView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct HistoryView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \BloodPressureReading.date, order: .reverse) private var readings: [BloodPressureReading]

  var body: some View {
    NavigationStack {
      Group {
        if readings.isEmpty {
          ContentUnavailableView(
            "No Readings Yet",
            systemImage: "heart.text.square",
            description: Text("Your blood pressure history will appear here.")
          )
        } else {
          List {
            ForEach(readings) { reading in
              NavigationLink {
                ReadingDetailView(reading: reading)
              } label: {
                ReadingRowView(reading: reading)
              }
            }
            .onDelete(perform: deleteReadings)
          }
        }
      }
      .navigationTitle("History")
      .toolbar {
        if !readings.isEmpty {
          EditButton()
        }
      }
    }
  }

  private func deleteReadings(at offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(readings[index])
    }
  }
}

#Preview {
  HistoryView()
    .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
