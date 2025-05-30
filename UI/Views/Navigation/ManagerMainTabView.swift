//
//  ManagerMainTabView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 20/05/2025.
//

import SwiftUI

struct ManagerMainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView {
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
            
            // 🆕 DODANY TAB Z PROFILEM
            ManagerProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

struct ManagerMainTabView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerMainTabView()
            .preferredColorScheme(.light)
            .previewDevice("iPhone 14")
        ManagerMainTabView()
            .preferredColorScheme(.dark)
            .previewDevice("iPhone 14")
    }
}
