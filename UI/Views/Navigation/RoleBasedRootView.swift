// UI/Views/Navigation/RoleBasedRootView.swift
import SwiftUI

/// Enhanced view that directs users to different main views based on their role
/// with smooth entrance animations and loading states
struct RoleBasedRootView: View {
    let userRole: String
    
    @State private var isAppearing = false
    @State private var backgroundOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 20
    @State private var contentOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background with subtle animation
            backgroundForRole(userRole)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            // Main content with entrance animation
            mainContentForRole(userRole)
                .opacity(contentOpacity)
                .offset(y: contentOffset)
        }
        .onAppear {
            startEntranceAnimations()
        }
        .preferredColorScheme(.dark) // Force dark mode for consistency
    }
    
    // MARK: - Background for each role
    @ViewBuilder
    private func backgroundForRole(_ role: String) -> some View {
        switch role {
        case "arbejder":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray.opacity(0.1),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "byggeleder":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrInfo.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "chef":
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrYellow.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            Color.clear
        }
    }
    
    // MARK: - Main content routing
    @ViewBuilder
    private func mainContentForRole(_ role: String) -> some View {
        switch role {
        case "arbejder":
            EnhancedWorkerMainView()
        case "byggeleder":
            EnhancedManagerMainView()
        case "chef":
            EnhancedBossMainView()
        case "system":
            EnhancedAdminMainView()
        default:
            EnhancedUnauthorizedView()
        }
    }
    
    // MARK: - Entrance Animations
    private func startEntranceAnimations() {
        // Quick background fade
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }
        
        // Staggered content entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                contentOffset = 0
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Enhanced Worker Main View
struct EnhancedWorkerMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            WorkerWorkHoursView()
                .tabItem {
                    Label("Hours", systemImage: selectedTab == 1 ? "clock.fill" : "clock")
                }
                .tag(1)
            
            WorkerTasksView()
                .tabItem {
                    Label("Tasks", systemImage: selectedTab == 2 ? "list.bullet" : "list.dash")
                }
                .tag(2)
            
            WorkerLeaveView()
                .tabItem {
                    Label("Leave", systemImage: selectedTab == 3 ? "calendar.badge.clock" : "calendar")
                }
                .tag(3)
            
            WorkerProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .accentColor(Color.ksrYellow)
        .onAppear {
            setupTabBarAppearance()
        }
    }
}

// MARK: - Enhanced Manager Main View
struct EnhancedManagerMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ManagerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            ManagerProjectsView()
                .tabItem {
                    Label("Projects", systemImage: selectedTab == 1 ? "folder.fill" : "folder")
                }
                .tag(1)
            
            ManagerWorkersView()
                .tabItem {
                    Label("Workers", systemImage: selectedTab == 2 ? "person.3.fill" : "person.3")
                }
                .tag(2)
            
            ManagerWorkPlansView()
                .tabItem {
                    Label("Work Plans", systemImage: selectedTab == 3 ? "calendar" : "calendar.badge.clock")
                }
                .tag(3)
            
            ChefLeaveManagementView()
                .tabItem {
                    Label("Leave", systemImage: selectedTab == 4 ? "calendar.badge.exclamationmark" : "calendar.badge.plus")
                }
                .tag(4)
            
            ManagerProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 5 ? "person.fill" : "person")
                }
                .tag(5)
        }
        .accentColor(Color.ksrYellow)
        .onAppear {
            setupTabBarAppearance()
        }
    }
}

// MARK: - Enhanced Boss Main View
struct EnhancedBossMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ChefDashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: selectedTab == 0 ? "chart.bar.fill" : "chart.bar")
                    }
                    .tag(0)
                
                CustomersListView()
                    .tabItem {
                        Label("Customers", systemImage: selectedTab == 1 ? "building.2.fill" : "building.2")
                    }
                    .tag(1)
                
                // 🔥 NAPRAWIONE: Zastąpiono ComingSoonView prawdziwym widokiem projektów
                ChefProjectsView()
                    .tabItem {
                        Label("Projects", systemImage: selectedTab == 2 ? "folder.fill" : "folder")
                    }
                    .tag(2)
                
                ChefWorkersManagementView()
                    .tabItem {
                        Label("Workers", systemImage: selectedTab == 3 ? "person.3.fill" : "person.3")
                    }
                    .tag(3)
                
                ChefLeaveManagementView()
                    .tabItem {
                        Label("Leave", systemImage: selectedTab == 4 ? "calendar.badge.exclamationmark" : "calendar.badge.plus")
                    }
                    .tag(4)
                
                ChefProfileView()
                    .tabItem {
                        Label("Profile", systemImage: selectedTab == 5 ? "person.fill" : "person")
                    }
                    .tag(5)
            }
            .accentColor(Color.ksrYellow)
            .onAppear {
                setupTabBarAppearance()
                print("🔍 Chef TabView loaded with 6 tabs including Leave")
            }
        }
    }
}

// MARK: - Enhanced Admin Main View
struct EnhancedAdminMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ComingSoonView(feature: "System Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: selectedTab == 0 ? "gearshape.fill" : "gearshape")
                }
                .tag(0)
            
            ComingSoonView(feature: "Users Management")
                .tabItem {
                    Label("Users", systemImage: selectedTab == 1 ? "person.3.fill" : "person.3")
                }
                .tag(1)
            
            ComingSoonView(feature: "System Settings")
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 2 ? "gearshape.2.fill" : "gearshape.2")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
        }
        .accentColor(Color.ksrYellow)
        .onAppear {
            setupTabBarAppearance()
        }
    }
}

// MARK: - Enhanced Unauthorized View
struct EnhancedUnauthorizedView: View {
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray,
                    Color.black.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Warning icon with animation
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.ksrError)
                    .scaleEffect(animateContent ? 1.0 : 0.5)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateContent)
                
                // Title and message
                VStack(spacing: 16) {
                    Text("Unauthorized Access")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    
                    Text("You do not have permission to access this app. Please contact your administrator.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 40)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        AuthService.shared.logout()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.title3)
                            
                            Text("Return to Login")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.ksrError)
                                .shadow(color: .ksrError.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
                    
                    Button(action: {
                        // Try to refresh/check auth again
                        // This could trigger a re-check of permissions
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(1.0), value: animateContent)
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
        .onAppear {
            animateContent = true
        }
    }
}

// MARK: - Coming Soon View
struct ComingSoonView: View {
    let feature: String
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated icon
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(.ksrYellow)
                .rotationEffect(.degrees(animateIcon ? 15 : -15))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateIcon)
            
            VStack(spacing: 12) {
                Text("\(feature)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.ksrYellow)
                
                Text("This feature is under development and will be available in a future update.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Version info
            VStack(spacing: 4) {
                Text("Expected in v1.1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Stay tuned for updates!")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            animateIcon = true
        }
    }
}

// MARK: - Tab Bar Appearance Setup
extension View {
    func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Background color
        appearance.backgroundColor = UIColor(Color.ksrDarkGray.opacity(0.95))
        
        // Selected item
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.ksrYellow)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.ksrYellow)
        ]
        
        // Normal item - używamy kolorów KSR
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.ksrSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.ksrSecondary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Backward Compatibility Views
// These maintain the original structure for any existing references

struct WorkerMainView: View {
    var body: some View {
        EnhancedWorkerMainView()
    }
}

struct ManagerMainView: View {
    var body: some View {
        EnhancedManagerMainView()
    }
}

struct BossMainView: View {
    var body: some View {
        EnhancedBossMainView()
    }
}

struct AdminMainView: View {
    var body: some View {
        EnhancedAdminMainView()
    }
}

struct UnauthorizedView: View {
    var body: some View {
        EnhancedUnauthorizedView()
    }
}

// MARK: - Previews
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
