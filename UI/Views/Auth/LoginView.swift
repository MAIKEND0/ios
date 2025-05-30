// LoginView.swift
// KSR Cranes App
// Created by Maksymilian Marcinowski on 13/05/2025.

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: FocusableField?
    
    // Dodatkowe stany dla lepszych animacji
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var logoScale: CGFloat = 1.0
    @State private var formOffset: CGFloat = 0
    
    enum FocusableField: Hashable {
        case email, password
    }

    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background dla lepszego wyglądu
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.ksrDarkGray,
                        Color.ksrDarkGray.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Logo Section
                        logoSection
                            .padding(.top, isKeyboardVisible ? 20 : 60)
                        
                        Spacer().frame(height: isKeyboardVisible ? 20 : 40)
                        
                        // MARK: - Login Form
                        loginFormSection
                            .padding(.horizontal, 24)
                            .offset(y: formOffset)
                        
                        Spacer().frame(height: 40)
                        
                        // MARK: - Version Info
                        if !isKeyboardVisible {
                            versionSection
                        }
                        
                        // Dodatkowy spacer dla klawiatury
                        Spacer().frame(height: keyboardHeight > 0 ? keyboardHeight : 0)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .onTapGesture {
                focusedField = nil
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
            .onReceive(keyboardPublisher) { height in
                handleKeyboardChange(height: height)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        Group {
            if isKeyboardVisible {
                // Kompaktowa wersja dla klawiatury
                HStack(alignment: .center, spacing: 12) {
                    Image("KSRLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KSR CRANES")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Kranfører Udlejning")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            } else {
                // Pełna wersja logo
                VStack(spacing: 16) {
                    Image("KSRLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                        .scaleEffect(logoScale)
                    
                    VStack(spacing: 8) {
                        Text("KSR CRANES")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Kranfører Udlejning")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isKeyboardVisible)
    }
    
    // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 24) {
            // Email Field
            CustomTextField(
                title: "Email",
                text: $viewModel.email,
                placeholder: "Enter your email",
                keyboardType: .emailAddress,
                textContentType: .username,
                isFocused: isEmailFocused
            )
            .focused($focusedField, equals: .email)
            .onChange(of: focusedField) { field in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEmailFocused = (field == .email)
                }
            }
            
            // Password Field
            CustomSecureField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Enter your password",
                isFocused: isPasswordFocused
            )
            .focused($focusedField, equals: .password)
            .onChange(of: focusedField) { field in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPasswordFocused = (field == .password)
                }
            }
            
            // Error Message
            if !viewModel.errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.ksrError)
                        .font(.caption)
                    
                    Text(viewModel.errorMessage)
                        .font(.caption)
                        .foregroundColor(.ksrError)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Login Button
            loginButton
            
            // Forgot Password
            forgotPasswordButton
        }
    }
    
    // MARK: - Custom Text Field
    private struct CustomTextField: View {
        let title: String
        @Binding var text: String
        let placeholder: String
        var keyboardType: UIKeyboardType = .default
        var textContentType: UITextContentType?
        let isFocused: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                TextField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.ksrLightGray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isFocused ? Color.ksrYellow : Color.white.opacity(0.2),
                                        lineWidth: isFocused ? 2 : 1
                                    )
                            )
                    )
                    .foregroundColor(.black)
                    .font(.body)
                    .scaleEffect(isFocused ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
    
    // MARK: - Custom Secure Field
    private struct CustomSecureField: View {
        let title: String
        @Binding var text: String
        let placeholder: String
        let isFocused: Bool
        @State private var isSecured = true
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    Group {
                        if isSecured {
                            SecureField(placeholder, text: $text)
                        } else {
                            TextField(placeholder, text: $text)
                        }
                    }
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    
                    Button(action: { isSecured.toggle() }) {
                        Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.ksrLightGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isFocused ? Color.ksrYellow : Color.white.opacity(0.2),
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                )
                .foregroundColor(.black)
                .font(.body)
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
    
    // MARK: - Login Button
    private var loginButton: some View {
        Button(action: {
            focusedField = nil
            viewModel.login()
        }) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                    
                    Text("Log in")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.ksrYellow,
                                Color.ksrYellow.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .ksrYellow.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
        .opacity((viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty) ? 0.6 : 1.0)
        .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
        .padding(.top, 8)
    }
    
    // MARK: - Forgot Password Button
    private var forgotPasswordButton: some View {
        Button(action: { viewModel.forgotPassword() }) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.caption)
                
                Text("Forgot password?")
                    .font(.subheadline)
                    .underline()
            }
            .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 8)
    }
    
    // MARK: - Version Section
    private var versionSection: some View {
        VStack(spacing: 8) {
            Text("v1.0.0")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            
            Text("© 2025 KSR Cranes")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Keyboard Handling
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { notification in
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
                },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
    
    private func handleKeyboardChange(height: CGFloat) {
        withAnimation(.easeOut(duration: 0.3)) {
            keyboardHeight = height
            
            // Animuj logo i formularz
            if height > 0 {
                logoScale = 0.8
                formOffset = -20
            } else {
                logoScale = 1.0
                formOffset = 0
            }
        }
    }
}

// MARK: - Previews
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            LoginView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}
