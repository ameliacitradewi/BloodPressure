//
//  ReadingDetailView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct ReadingDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @Bindable var reading: BloodPressureReading
  @State private var showEditSheet = false
  @State private var showDeleteConfirmation = false

  var body: some View {
    List {
      Section("Reading") {
        LabeledContent("Blood Pressure", value: reading.formattedBP)
        LabeledContent("Pulse", value: reading.pulse.map { "\($0) BPM" } ?? "—")
        LabeledContent("Status") {
          StatusBadge(category: reading.category)
        }
        LabeledContent("Date", value: reading.date.formatted(date: .abbreviated, time: .shortened))
      }

      Section("Details") {
        LabeledContent("Position", value: reading.position)
        LabeledContent("Arm", value: reading.arm)
        if !reading.notes.isEmpty {
          LabeledContent("Notes", value: reading.notes)
        }
      }
    }
    .navigationTitle("Reading Detail")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button("Edit") { showEditSheet = true }
          Button("Delete", role: .destructive) { showDeleteConfirmation = true }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .sheet(isPresented: $showEditSheet) {
      EditReadingView(reading: reading)
    }
    .alert("Delete Reading?", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        modelContext.delete(reading)
        dismiss()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone.")
    }
  }
}
