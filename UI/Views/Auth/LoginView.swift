//
//  LoginView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.ksrLightGray.ignoresSafeArea()
                
                VStack {
                    // Logo and Header
                    VStack(spacing: 20) {
                        // Logo
                        ZStack {
                            Rectangle()
                                .fill(Color.ksrYellow)
                                .frame(width: 120, height: 120)
                                .cornerRadius(16)
                            Text("KSR")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 60)
                        
                        // App name
                        Text("KSR CRANES")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.ksrDarkGray)
                        
                        // Subtitle
                        Text("Employee Portal")
                            .font(.headline)
                            .foregroundColor(Color.ksrMediumGray)
                            .padding(.bottom, 40)
                    }
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(Color.ksrDarkGray)
                            
                            TextField("", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.ksrMediumGray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(Color.ksrDarkGray)
                            
                            SecureField("", text: $viewModel.password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.ksrMediumGray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Error message (if any)
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                        
                        // Login button
                        Button(action: {
                            viewModel.login()
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.ksrYellow)
                                    .cornerRadius(10)
                            } else {
                                Text("Login")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.ksrYellow)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.top, 10)
                        
                        // Forgot password button
                        Button(action: {
                            // Handle forgot password
                            viewModel.forgotPassword()
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(Color.ksrMediumGray)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Version info
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundColor(Color.ksrMediumGray)
                        .padding(.bottom, 20)
                }
            }
            .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
                // Use the role-based router instead of directly going to MainTabView
                RoleBasedRootView(userRole: viewModel.userRole)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
