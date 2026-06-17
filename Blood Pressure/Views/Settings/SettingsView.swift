//
//  SettingsView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct SettingsView: View {
  @Query(sort: \BloodPressureReading.date, order: .reverse) private var readings: [BloodPressureReading]
  @AppStorage(UserSettings.userNameKey) private var userName = ""

  @State private var exportURL: URL?
  @State private var showShareSheet = false
  @State private var showExportError = false

  var body: some View {
    NavigationStack {
      Form {
        Section("Profile") {
          TextField("Your Name", text: $userName)
            .textContentType(.name)
            .autocorrectionDisabled()
        }

        Section("Reminders") {
          NavigationLink {
            ReminderView()
          } label: {
            Label("Manage Reminders", systemImage: "bell.badge.fill")
          }
        }

        Section("Data") {
          Button {
            exportData()
          } label: {
            Label("Export Data to CSV", systemImage: "square.and.arrow.up")
          }
        }

        Section("Health Disclaimer") {
          Text(UserSettings.healthDisclaimer)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Section("App Info") {
          LabeledContent("App Name", value: "Blood Pressure Tracker")
          LabeledContent("Version", value: "1.0.0")
          LabeledContent("Storage", value: "Local on device")
        }
      }
      .navigationTitle("Settings")
      .sheet(isPresented: $showShareSheet) {
        if let exportURL {
          ShareSheet(items: [exportURL])
        }
      }
      .alert("Export Failed", isPresented: $showExportError) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Could not create the CSV file.")
      }
    }
  }

  private func exportData() {
    guard let url = CSVExporter.export(readings: readings) else {
      showExportError = true
      return
    }
    exportURL = url
    showShareSheet = true
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
  SettingsView()
    .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
