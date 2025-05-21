//
//  MainTabView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var userRole: String = AuthService.shared.getEmployeeRole() ?? "arbejder"
    
    var body: some View {
        TabView {
            if userRole == "byggeleder" {
                // Zakładki dla menedżera
                ManagerDashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                
                ManagerProjectsView()
                    .tabItem {
                        Label("Projects", systemImage: "folder.fill")
                    }
                
                ManagerWorkersView()
                    .tabItem {
                        Label("Workers", systemImage: "person.3.fill")
                    }
                
                ManagerWorkPlansView()
                    .tabItem {
                        Label("Work Plans", systemImage: "calendar")
                    }
            } else {
                // Zakładki dla pracownika
                WorkerDashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                
                WorkerWorkHoursView()
                    .tabItem {
                        Label("Hours", systemImage: "clock.fill")
                    }
                
                WorkerTasksView()
                    .tabItem {
                        Label("Tasks", systemImage: "list.bullet")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
        }
        .accentColor(.ksrYellow)
        .onAppear {
            userRole = AuthService.shared.getEmployeeRole() ?? "arbejder"
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .preferredColorScheme(.light)
            .previewDevice("iPhone 14")
        MainTabView()
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 14")
    }
}
