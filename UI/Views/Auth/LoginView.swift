// LoginView.swift - OPTIMIZED VERSION
// KSR Cranes App

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: FocusableField?
    
    // Simplified animation states - reduced for performance
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var logoScale: CGFloat = 1.0
    @State private var formOffset: CGFloat = 0
    @State private var formOpacity: Double = 0.0
    @State private var logoOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    
    enum FocusableField: Hashable {
        case email, password
    }

    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                // ✅ SIMPLIFIED BACKGROUND - much lighter
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.ksrDarkGray,
                        Color.black.opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Logo Section
                        logoSection
                            .padding(.top, isKeyboardVisible ? 20 : 60)
                            .opacity(logoOpacity)
                        
                        Spacer().frame(height: isKeyboardVisible ? 20 : 40)
                        
                        // MARK: - Login Form - OPTIMIZED
                        loginFormSection
                            .padding(.horizontal, 24)
                            .offset(y: formOffset)
                            .opacity(formOpacity)
                        
                        Spacer().frame(height: 40)
                        
                        // MARK: - Version Info
                        if !isKeyboardVisible {
                            versionSection
                                .opacity(formOpacity)
                        }
                        
                        // Keyboard spacer
                        Spacer().frame(height: keyboardHeight > 0 ? keyboardHeight : 0)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .onTapGesture {
                // ✅ IMMEDIATE RESPONSE - no animation delays
                focusedField = nil
                hideKeyboard()
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
            .onAppear {
                startLoginViewAnimations()
            }
            .onChange(of: viewModel.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    #if DEBUG
                    print("[LoginView] ✅ Login successful, AppContainerView will handle navigation")
                    #endif
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - SIMPLIFIED Animations
    private func startLoginViewAnimations() {
        // ✅ FASTER, SIMPLER animations
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                formOpacity = 1.0
            }
        }
    }
    
    // MARK: - SIMPLIFIED Logo Section
    private var logoSection: some View {
        Group {
            if isKeyboardVisible {
                // Compact version
                HStack(alignment: .center, spacing: 12) {
                    Image("KSRLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
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
                // Full version - SIMPLIFIED shadows
                VStack(spacing: 20) {
                    Image("KSRLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: .ksrYellow.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(logoScale)
                    
                    VStack(spacing: 12) {
                        Text("KSR CRANES")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Kranfører Udlejning")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Simple underline
                        Rectangle()
                            .fill(Color.ksrYellow)
                            .frame(width: formOpacity * 120, height: 2)
                            .animation(.easeInOut(duration: 0.5), value: formOpacity)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
    }
    
    // MARK: - OPTIMIZED Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 24) {
            // ✅ OPTIMIZED Email Field - instant response
            OptimizedTextField(
                title: "Email",
                text: $viewModel.email,
                placeholder: "Enter your email",
                keyboardType: .emailAddress,
                textContentType: .username,
                isFocused: isEmailFocused
            )
            .focused($focusedField, equals: .email)
            .onChange(of: focusedField) { _, field in
                // ✅ NO ANIMATION for instant response
                isEmailFocused = (field == .email)
            }
            
            // ✅ OPTIMIZED Password Field
            OptimizedSecureField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Enter your password",
                isFocused: isPasswordFocused
            )
            .focused($focusedField, equals: .password)
            .onChange(of: focusedField) { _, field in
                // ✅ NO ANIMATION for instant response
                isPasswordFocused = (field == .password)
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
            }
            
            // ✅ OPTIMIZED Login Button
            optimizedLoginButton
            
            // Forgot Password
            forgotPasswordButton
        }
    }
    
    // MARK: - OPTIMIZED Text Field - No lag
    private struct OptimizedTextField: View {
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
                    // ✅ REMOVED scaleEffect animation - causes lag
            }
        }
    }
    
    // MARK: - OPTIMIZED Secure Field - No lag
    private struct OptimizedSecureField: View {
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
                // ✅ REMOVED scaleEffect animation - causes lag
            }
        }
    }
    
    // MARK: - OPTIMIZED Login Button
    private var optimizedLoginButton: some View {
        Button(action: {
            // ✅ IMMEDIATE response
            focusedField = nil
            hideKeyboard()
            
            // Small delay for keyboard to hide, then login
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.login()
            }
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
                    .fill(Color.ksrYellow)
                    // ✅ SIMPLIFIED gradient - less GPU load
            )
        }
        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
        .opacity((viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty) ? 0.6 : 1.0)
        // ✅ REMOVED scaleEffect animation
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
    
    // MARK: - OPTIMIZED Keyboard Handling
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
        // ✅ FASTER animation
        withAnimation(.easeOut(duration: 0.2)) {
            keyboardHeight = height
            
            if height > 0 {
                logoScale = 0.8
                formOffset = -20
            } else {
                logoScale = 1.0
                formOffset = 0
            }
        }
    }
    
    // ✅ OPTIMIZED keyboard hiding
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
