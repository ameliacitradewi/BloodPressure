//
//  AppTheme.swift
//  Blood Pressure
//

import SwiftUI

enum AppTheme {
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let accent = Color(red: 0.21, green: 0.34, blue: 0.56)
    static let secondaryAccent = Color(red: 0.18, green: 0.55, blue: 0.75)
}

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct StatusBadge: View {
    let category: BloodPressureCategory

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.iconName)
            Text(category.rawValue)
                .fontWeight(.semibold)
        }
        .font(.caption)
        .foregroundStyle(category.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(category.color.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(category.rawValue)")
    }
}

struct ReadingRowView: View {
    let reading: BloodPressureReading

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(reading.formattedBP)
                    .font(.headline)
                Text(reading.date, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !reading.notes.isEmpty {
                    Text(reading.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(category: reading.category)
                if let pulse = reading.pulse {
                    Label("\(pulse) BPM", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PermissionDeniedView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        CardView {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct HealthDisclaimerView: View {
    var body: some View {
        Text(UserSettings.healthDisclaimer)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}
