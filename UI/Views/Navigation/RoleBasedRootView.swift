//
//  RoleBasedRootView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

/// View that directs users to different main views based on their role
struct RoleBasedRootView: View {
    let userRole: String
    
    var body: some View {
        switch userRole {
        case "arbejder":
            // Worker view
            WorkerMainView()
        case "byggeleder":
            // Manager view
            ManagerMainView()
        case "chef":
            // Boss view
            BossMainView()
        case "system":
            // Admin view
            AdminMainView()
        default:
            // Fallback or unauthorized view
            UnauthorizedView()
        }
    }
}

// Worker's main view - this is your existing MainTabView
struct WorkerMainView: View {
    var body: some View {
        MainTabView()
    }
}

// Manager's main view
struct ManagerMainView: View {
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
            
            TimesheetReportsView()
                .tabItem {
                    Label("Timesheets", systemImage: "doc.text.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

// Boss's main view
struct BossMainView: View {
    var body: some View {
        // Replace with actual boss UI when implemented
        TabView {
            Text("Executive Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            Text("Analytics")
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")
                }
            
            Text("Management")
                .tabItem {
                    Label("Management", systemImage: "building.2.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

// Admin's main view
struct AdminMainView: View {
    var body: some View {
        // Replace with actual admin UI when implemented
        TabView {
            Text("System Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "gearshape.fill")
                }
            
            Text("Users")
                .tabItem {
                    Label("Users", systemImage: "person.3.fill")
                }
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.2.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(Color.ksrYellow)
    }
}

// View for unauthorized users or unknown roles
struct UnauthorizedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(Color.ksrYellow)
            
            Text("Unauthorized Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You do not have permission to access this app. Please contact your administrator.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                // Logout
                AuthService.shared.logout()
            }) {
                Text("Return to Login")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ksrYellow)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
    }
}

struct RoleBasedRootView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RoleBasedRootView(userRole: "arbejder")
                .previewDisplayName("Worker View")
            
            RoleBasedRootView(userRole: "byggeleder")
                .previewDisplayName("Manager View")
            
            RoleBasedRootView(userRole: "chef")
                .previewDisplayName("Boss View")
            
            RoleBasedRootView(userRole: "system")
                .previewDisplayName("Admin View")
            
            RoleBasedRootView(userRole: "unknown")
                .previewDisplayName("Unauthorized View")
        }
    }
}
