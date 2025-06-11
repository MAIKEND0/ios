//
//  ChefProfileView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 30/05/2025.
//

import SwiftUI

struct ChefProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogoutConfirmation = false
    @State private var navigateToLogin = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Profile Stats
                    profileStats
                    
                    // Profile Options
                    profileOptions
                    
                    // System Information
                    systemInfoSection
                    
                    // Logout Section
                    logoutSection
                }
                .padding()
            }
            .background(profileBackground)
            .navigationTitle("Chief Executive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(Color.ksrYellow)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToLogin) {
            LoginView()
        }
        .sheet(isPresented: $showEditProfile) {
            ChefEditProfileView()
        }
        .confirmationDialog("Logout", isPresented: $showingLogoutConfirmation) {
            Button("Logout", role: .destructive) {
                performLogout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Picture Placeholder
            ZStack {
                Circle()
                    .fill(Color.ksrLightGray)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.ksrYellow, lineWidth: 3)
                    )
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.ksrYellow)
                
                // Plus button overlay for future photo upload
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.ksrPrimary)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: -4, y: -4)
                    }
                }
                .frame(width: 100, height: 100)
            }
            .onTapGesture {
                // TODO: Add photo picker functionality
                print("Profile photo tapped")
            }
            
            VStack(spacing: 8) {
                Text(AuthService.shared.getEmployeeName() ?? "Chief Executive")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(Color.ksrYellow)
                        .font(.system(size: 14))
                    
                    Text("Chief Executive Officer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(Color.ksrInfo)
                        .font(.system(size: 14))
                    
                    Text("ID: \(AuthService.shared.getEmployeeId() ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.ksrInfo)
                        .fontWeight(.medium)
                }
                
                // Email if available
                if AuthService.shared.getEmployeeName() != nil {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Color.ksrSecondary)
                            .font(.system(size: 14))
                        
                        Text("chief@ksrcranes.dk")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Profile Stats
    private var profileStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Company Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                ChefStatCard(title: "Companies", value: "15", icon: "building.2.fill", color: .ksrInfo)
                ChefStatCard(title: "Projects", value: "31", icon: "folder.fill", color: .ksrSuccess)
                ChefStatCard(title: "Employees", value: "26", icon: "person.3.fill", color: .ksrPrimary)
            }
            
            HStack(spacing: 12) {
                ChefStatCard(title: "Revenue", value: "2.1M", subtitle: "DKK", icon: "chart.line.uptrend.xyaxis", color: .ksrWarning)
                ChefStatCard(title: "Tasks", value: "34", icon: "list.bullet.rectangle", color: .ksrSecondary)
                ChefStatCard(title: "Efficiency", value: "94%", icon: "speedometer", color: .ksrSuccess)
            }
        }
    }
    
    // MARK: - Profile Options
    private var profileOptions: some View {
        VStack(spacing: 12) {
            ProfileOptionRow(
                icon: "person.crop.circle",
                title: "Edit Profile",
                subtitle: "Update personal information",
                color: .ksrPrimary
            ) {
                showEditProfile = true
            }
            
            ProfileOptionRow(
                icon: "bell.badge",
                title: "Notifications",
                subtitle: "Manage notification preferences",
                color: .ksrWarning
            ) {
                // TODO: Navigate to notifications settings
                print("Notifications tapped")
            }
            
            ProfileOptionRow(
                icon: "chart.bar.fill",
                title: "Business Analytics",
                subtitle: "View detailed reports and insights",
                color: .ksrInfo
            ) {
                // TODO: Navigate to analytics
                print("Analytics tapped")
            }
            
            ProfileOptionRow(
                icon: "building.2.fill",
                title: "Company Management",
                subtitle: "Manage customers and projects",
                color: .ksrSuccess
            ) {
                // TODO: Navigate to company management
                print("Company Management tapped")
            }
            
            ProfileOptionRow(
                icon: "person.3.fill",
                title: "Employee Management",
                subtitle: "Manage workers and supervisors",
                color: .ksrPrimary
            ) {
                // TODO: Navigate to employee management
                print("Employee Management tapped")
            }
            
            ProfileOptionRow(
                icon: "gearshape.fill",
                title: "System Settings",
                subtitle: "Configure system preferences",
                color: .ksrSecondary
            ) {
                // TODO: Navigate to system settings
                print("Settings tapped")
            }
            
            // Always show biometric settings - the component itself will handle availability
            BiometricSettingRow()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - System Information
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                SystemInfoRow(label: "App Version", value: "1.0.0")
                SystemInfoRow(label: "Build", value: "2025.05.30")
                SystemInfoRow(label: "Role", value: "Chief Executive")
                SystemInfoRow(label: "Access Level", value: "Full Administrative")
                SystemInfoRow(label: "Last Login", value: "Today at 09:15")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        Button {
            showingLogoutConfirmation = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Logout")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.ksrError,
                                Color.ksrError.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.ksrError.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Background
    private var profileBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color(.systemBackground),
                colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6).opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Methods
    private func performLogout() {
        AuthService.shared.logout()
        
        // Clear additional data
        let keysToRemove = [
            "isLoggedIn", "userToken", "employeeId", "employeeName", "userRole"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        
        // Clear API service tokens
        ManagerAPIService.shared.authToken = nil
        WorkerAPIService.shared.authToken = nil
        
        #if DEBUG
        print("[ChefProfileView] User logged out successfully")
        #endif
        
        DispatchQueue.main.async {
            self.navigateToLogin = true
        }
    }
}

// MARK: - Supporting Views

struct ChefStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.3) : Color(.systemGray6))
        )
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BiometricSettingRow: View {
    @State private var isBiometricEnabled = AuthService.shared.isBiometricEnabled
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private var biometricType: String {
        return AuthService.shared.biometricType
    }
    
    private var isBiometricAvailable: Bool {
        return AuthService.shared.isBiometricAvailable
    }
    
    var body: some View {
        Group {
            if isBiometricAvailable {
                HStack(spacing: 16) {
                    Image(systemName: biometricType == "Face ID" ? "faceid" : "touchid")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.ksrSuccess)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(biometricType) Login")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Use \(biometricType) for secure sign in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isBiometricEnabled)
                        .labelsHidden()
                        .onChange(of: isBiometricEnabled) { _, newValue in
                            toggleBiometric(enabled: newValue)
                        }
                        .tint(.ksrYellow)
                }
                .padding(.vertical, 8)
                .onAppear {
                    // Refresh the state when view appears
                    isBiometricEnabled = AuthService.shared.isBiometricEnabled
                    
                    #if DEBUG
                    print("[BiometricSettingRow] Biometric available: \(isBiometricAvailable)")
                    print("[BiometricSettingRow] Biometric type: \(biometricType)")
                    print("[BiometricSettingRow] Biometric enabled: \(isBiometricEnabled)")
                    print("[BiometricSettingRow] Has stored credentials: \(BiometricAuthService.shared.getStoredCredentials() != nil)")
                    #endif
                }
            } else {
                // Show a disabled state when biometric is not available
                HStack(spacing: 16) {
                    Image(systemName: "faceid")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Biometric Login")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text("Not available on this device")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .alert("Biometric Settings", isPresented: $showBiometricError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(biometricErrorMessage)
        }
    }
    
    private func toggleBiometric(enabled: Bool) {
        if enabled {
            // Check if we already have stored credentials
            if BiometricAuthService.shared.getStoredCredentials() != nil {
                // We already have credentials, just enable it
                BiometricAuthService.shared.isBiometricEnabled = true
                isBiometricEnabled = true
                
                #if DEBUG
                print("[BiometricSettingRow] Biometric re-enabled with existing credentials")
                #endif
            } else {
                // To enable biometric, we need current credentials
                // Since we're already logged in, we can't get the password
                // Show an error message
                biometricErrorMessage = "To enable \(biometricType), please:\n1. Log out of the app\n2. Sign in with your email and password\n3. Accept the \(biometricType) prompt after logging in"
                showBiometricError = true
                isBiometricEnabled = false
            }
        } else {
            // Disable biometric
            AuthService.shared.disableBiometric()
            isBiometricEnabled = false
            
            #if DEBUG
            print("[BiometricSettingRow] Biometric disabled")
            #endif
        }
    }
}

struct SystemInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Edit Profile View
struct ChefEditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Profile editing functionality will be implemented in future updates.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct ChefProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChefProfileView()
                .preferredColorScheme(.light)
            ChefProfileView()
                .preferredColorScheme(.dark)
        }
    }
}
