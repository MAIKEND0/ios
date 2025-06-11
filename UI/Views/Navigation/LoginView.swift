// LoginView.swift - OPTIMIZED VERSION
// KSR Cranes App

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: FocusableField?
    
    // ✅ MINIMIZED states for better performance
    @State private var logoScale: CGFloat = 1.0
    @State private var formOffset: CGFloat = 0
    @State private var viewOpacity: Double = 0.0
    @State private var isPasswordSecured = true
    @State private var showBiometricPrompt = false
    
    enum FocusableField: Hashable {
        case email, password
    }

    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        ZStack {
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
                .opacity(viewOpacity)

                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Logo Section
                        logoSection
                            .padding(.top, isKeyboardVisible ? 20 : 60)
                            .opacity(viewOpacity)
                        
                        Spacer().frame(height: isKeyboardVisible ? 20 : 40)
                        
                        // MARK: - Login Form - OPTIMIZED
                        loginFormSection
                            .padding(.horizontal, 24)
                            .offset(y: formOffset)
                            .opacity(viewOpacity)
                        
                        Spacer().frame(height: 40)
                        
                        // MARK: - Version Info
                        if !isKeyboardVisible {
                            versionSection
                                .opacity(viewOpacity)
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
                
                #if DEBUG
                // Reset biometric prompt date for testing
                BiometricAuthService.shared.resetPromptDate()
                #endif
                
                viewModel.checkBiometricStatus()
            }
            // Removed onChange for isLoggedIn - navigation is handled by AppContainerView
            .onChange(of: viewModel.showBiometricPrompt) { _, showPrompt in
                #if DEBUG
                print("[LoginView] 🔔 showBiometricPrompt changed to: \(showPrompt)")
                #endif
            }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .alert("Enable \(viewModel.biometricType)?", isPresented: $viewModel.showBiometricPrompt) {
                Button("Enable") {
                    #if DEBUG
                    print("[LoginView] User tapped Enable for biometric")
                    #endif
                    viewModel.enableBiometric()
                }
                Button("Not Now", role: .cancel) {
                    #if DEBUG
                    print("[LoginView] User tapped Not Now for biometric")
                    #endif
                    viewModel.dismissBiometricPrompt()
                }
            } message: {
                Text("Would you like to enable \(viewModel.biometricType) for faster sign in next time?")
            }
        }
    }
    
    // MARK: - ULTRA SIMPLIFIED Animations - ONE state change
    private func startLoginViewAnimations() {
        // ✅ SINGLE animation for instant performance
        withAnimation(.easeOut(duration: 0.4)) {
            viewOpacity = 1.0
            logoScale = 1.0
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
                            .frame(width: viewOpacity * 120, height: 2)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
    }
    
    // MARK: - ULTRA FAST Login Form Section - IDENTICAL FIELDS
    private var loginFormSection: some View {
        VStack(spacing: 24) {
            // ✅ Email Field
            createTextField(
                title: "Email", 
                text: $viewModel.email,
                placeholder: "Enter your email",
                field: .email,
                isSecure: false
            )
            
            // ✅ Password Field - SAME SIZE as email
            createTextField(
                title: "Password",
                text: $viewModel.password, 
                placeholder: "Enter your password",
                field: .password,
                isSecure: true
            )
            
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
            
            // Face ID/Touch ID Button
            if viewModel.showBiometricButton {
                biometricLoginButton
            }
            
            // Forgot Password
            forgotPasswordButton
        }
    }
    
    // MARK: - IDENTICAL Text Field Creator - No size differences
    private func createTextField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        field: FocusableField,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 0) {
                Group {
                    if isSecure && isPasswordSecured {
                        SecureField(placeholder, text: text)
                    } else {
                        TextField(placeholder, text: text)
                    }
                }
                .textContentType(isSecure ? .password : .username)
                .keyboardType(isSecure ? .default : .emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($focusedField, equals: field)
                .foregroundColor(.ksrTextPrimary) // ✅ ADAPTIVE text color
                .font(.body)
                
                // Eye button only for password field
                if isSecure {
                    Button(action: { isPasswordSecured.toggle() }) {
                        Image(systemName: isPasswordSecured ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.ksrTextSecondary) // ✅ ADAPTIVE icon color
                            .font(.system(size: 18))
                            .frame(width: 24, height: 24) // ✅ Compact but tappable
                    }
                    .padding(.trailing, 4)
                } else {
                    // ✅ INVISIBLE spacer to match password field width exactly
                    Spacer()
                        .frame(width: 28, height: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(height: 56) // ✅ FIXED HEIGHT for both fields
            .background(Color.ksrLightGray) // ✅ Already adaptive: white in light, dark gray in dark mode
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == field ? Color.ksrYellow : Color.ksrBorder, lineWidth: 2) // ✅ ADAPTIVE border
            )
        }
    }
    
    // MARK: - Biometric Login Button
    private var biometricLoginButton: some View {
        Button(action: {
            focusedField = nil
            hideKeyboard()
            viewModel.loginWithBiometric()
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.biometricType == "Face ID" ? "faceid" : "touchid")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Sign in with \(viewModel.biometricType)")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.ksrDarkGray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
    
    // MARK: - ULTRA FAST Login Button - Better targeting
    private var optimizedLoginButton: some View {
        Button(action: {
            // ✅ IMMEDIATE response
            focusedField = nil
            hideKeyboard()
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
            .frame(maxWidth: .infinity, minHeight: 56) // ✅ LARGER touch area
            .background(Color.ksrYellow)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
        .opacity((viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty) ? 0.6 : 1.0)
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
