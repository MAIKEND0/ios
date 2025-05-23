// LoginView.swift
// KSR Cranes App
// Created by Maksymilian Marcinowski on 13/05/2025.

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var keyboardHeight: CGFloat = 0

    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.ksrDarkGray
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        
                        // --- Logo + Headers Section ---
                        Group {
                            if isKeyboardVisible {
                                HStack(alignment: .center, spacing: 12) {
                                    Image("KSRLogo")
                                        .resizable().scaledToFit().frame(width: 40, height: 40)
                                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("KSR CRANES")
                                            .font(.title2).bold().foregroundColor(.white).lineLimit(1)
                                        Text("Kranfører Udlejning")
                                            .font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 16) {
                                    Image("KSRLogo")
                                        .resizable().scaledToFit().frame(width: 100, height: 100)
                                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    Text("KSR CRANES")
                                        .font(.largeTitle).bold().foregroundColor(.white)
                                    Text("Kranfører Udlejning")
                                        .font(.subheadline).foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.top, isKeyboardVisible ? 20 : 60)
                        .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)

                        // --- Login Form Section ---
                        VStack(spacing: 20) {
                            // Email
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(.caption).bold()
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("Enter your email", text: $viewModel.email)
                                    .textContentType(.username)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    // Zwiększony wewnętrzny padding dla lepszego obszaru dotyku i wyglądu
                                    .padding(EdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12))
                                    .frame(minHeight: 50) // Utrzymuje minimalną wysokość
                                    .background(Color.ksrLightGray)
                                    .cornerRadius(8)
                                    .foregroundColor(.black) // Kolor wprowadzanego tekstu
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .contentShape(Rectangle()) // Definiuje obszar dotyku jako cały prostokąt pola
                                    // Usunięto .padding(.vertical, 4) stąd, aby nie zmniejszać obszaru dotyku
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.caption).bold()
                                    .foregroundColor(.white.opacity(0.8))

                                SecureField("Enter your password", text: $viewModel.password)
                                    .textContentType(.password)
                                    // Zwiększony wewnętrzny padding
                                    .padding(EdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12))
                                    .frame(minHeight: 50)
                                    .background(Color.ksrLightGray)
                                    .cornerRadius(8)
                                    .foregroundColor(.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .contentShape(Rectangle())
                                    // Usunięto .padding(.vertical, 4) stąd
                            }

                            // Error message
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                            }

                            // Login button
                            Button(action: { viewModel.login() }) {
                                HStack {
                                    Spacer()
                                    if viewModel.isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Log in").font(.headline).foregroundColor(.black)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .frame(minHeight: 50)
                                .background(Color.ksrYellow)
                                .cornerRadius(8)
                            }
                            .disabled(viewModel.isLoading)

                            // Forgot password?
                            Button("Forgot password?") { viewModel.forgotPassword() }
                                .font(.footnote).foregroundColor(.white.opacity(0.7))
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: keyboardHeight > 0 ? 20 : 100)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("v1.0.0")
                            .font(.caption2).foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 16)
                    }
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : 0)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .onTapGesture {
                UIApplication.shared.hideKeyboard()
            }
            .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
                RoleBasedRootView(userRole: viewModel.userRole)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = keyboardFrame.height }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) { keyboardHeight = 0 }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Upewnij się, że RoleBasedRootView jest zdefiniowany gdzieś w projekcie
// struct RoleBasedRootView: View {
//     var userRole: String
//     var body: some View {
//         Text("Welcome! Role: \(userRole.isEmpty ? "Undefined" : userRole)")
//     }
// }

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}
