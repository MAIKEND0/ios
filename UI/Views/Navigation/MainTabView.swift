//
//  MainTabView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Dashboard
            WorkerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            // Work Hours
            WorkerWorkHoursView()
                .tabItem {
                    Label("Hours", systemImage: "clock.fill")
                }

            // Tasks
            WorkerTasksView()
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet")
                }

            // Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.ksrYellow)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .preferredColorScheme(.light)
            .previewDevice("iPhone 14")
    }
}
