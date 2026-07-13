//
//  MainTabView.swift
//  Blood Pressure
//

// updated per 20 Jun
import SwiftUI
import SwiftData

struct MainTabView: View {
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      HomeView()
        .tabItem {
          Label("Home", systemImage: "house.fill")
        }
        .tag(0)

      HistoryView()
        .tabItem {
          Label("History", systemImage: "clock.fill")
        }
        .tag(1)

      AddReadingView2()
        .tabItem {
          Label("Add", systemImage: "plus.circle.fill")
        }
        .tag(2)

      TrendsView()
        .tabItem {
          Label("Trends", systemImage: "chart.xyaxis.line")
        }
        .tag(3)

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
        .tag(4)
    }
    .tint(AppTheme.accent)
  }
}

#Preview {
  MainTabView()
    .modelContainer(for: BloodPressureReading.self, inMemory: true)
}
