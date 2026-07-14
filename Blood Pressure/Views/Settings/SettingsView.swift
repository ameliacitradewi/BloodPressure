//
//  SettingsView.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \BloodPressureReading.date, order: .reverse)
    private var readings: [BloodPressureReading]

    @AppStorage(UserSettings.userNameKey)
    private var userName = ""

    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showExportError = false

    var body: some View {
        NavigationStack {
            ZStack {
                HomePalette.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection

                        settingsFormContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Export Failed", isPresented: $showExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not create the CSV file.")
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(HomePalette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsFormContent: some View {
        VStack(spacing: 16) {
            settingsSection(title: "Profile") {
                TextField("Your Name", text: $userName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .font(.system(.body, weight: .regular))
                    .foregroundStyle(HomePalette.primaryText)
                    .tint(HomePalette.primaryBlue)
            }

            settingsSection(title: "Reminders") {
                NavigationLink {
                    ReminderView()
                } label: {
                    Label("Manage Reminders", systemImage: "bell.badge.fill")
                        .font(.system(.body, weight: .regular))
                        .foregroundStyle(HomePalette.primaryText)
                }
            }

            settingsSection(title: "Data") {
                Button {
                    exportData()
                } label: {
                    Label("Export Data to CSV", systemImage: "square.and.arrow.up")
                        .font(.system(.body, weight: .regular))
                        .foregroundStyle(HomePalette.primaryBlue)
                }
            }

            settingsSection(title: "App Info") {
                LabeledContent("App Name", value: "Blood Pressure Tracker")
                    .font(.system(.body, weight: .regular))
                    .foregroundStyle(HomePalette.primaryText)

                Divider()

                LabeledContent("Version", value: "1.0.0")
                    .font(.system(.body, weight: .regular))
                    .foregroundStyle(HomePalette.primaryText)
            }

            settingsSection(title: "Disclaimer") {
                Text(UserSettings.healthDisclaimer)
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(HomePalette.primaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(HomePalette.primaryText)
//                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white)
                    .shadow(
                        color: .black.opacity(0.045),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            )
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

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { }
}

#Preview {
    SettingsView()
        .modelContainer(
            for: BloodPressureReading.self,
            inMemory: true
        )
}
