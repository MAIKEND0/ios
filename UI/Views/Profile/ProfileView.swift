//
//  ProfileView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI

struct ProfileView: View {
    @State private var showingLogoutConfirmation = false
    @State private var navigateToLogin = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    if let name = AuthService.shared.getEmployeeName() {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(name)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let employeeId = AuthService.shared.getEmployeeId() {
                        HStack {
                            Text("Employee ID")
                            Spacer()
                            Text(employeeId)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let role = AuthService.shared.getEmployeeRole() {
                        HStack {
                            Text("Role")
                            Spacer()
                            Text(role.capitalized)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("App")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack {
                            Text("Logout")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert(isPresented: $showingLogoutConfirmation) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Logout")) {
                        // Perform logout
                        AuthService.shared.logout()
                        navigateToLogin = true
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $navigateToLogin) {
                LoginView()
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
