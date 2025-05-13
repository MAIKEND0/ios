// MainTabView.swift
// KSR Cranes App
//
// Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WorkerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            WorkHoursView()
                .tabItem {
                    Label("Hours", systemImage: "clock.fill")
                }

            Text("Projects View Coming Soon")
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }

            Text("Profile View Coming Soon")
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
