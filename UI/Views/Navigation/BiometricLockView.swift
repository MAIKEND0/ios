import SwiftUI

struct BiometricLockView: View {
    @StateObject private var viewModel = BiometricLockViewModel()
    @State private var isUnlocked = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray,
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if !isUnlocked {
                // Lock screen content
                VStack(spacing: 40) {
                    // Logo
                    Image("KSRLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: .ksrYellow.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 20) {
                        Text("KSR CRANES")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("App Locked")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Face ID Button
                    Button(action: {
                        viewModel.authenticateWithBiometric()
                    }) {
                        VStack(spacing: 16) {
                            Image(systemName: viewModel.biometricType == "Face ID" ? "faceid" : "touchid")
                                .font(.system(size: 60))
                                .foregroundColor(.ksrYellow)
                            
                            Text("Unlock with \(viewModel.biometricType)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(width: 200, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.ksrYellow.opacity(0.5), lineWidth: 2)
                                )
                        )
                    }
                    .disabled(viewModel.isAuthenticating)
                    
                    // Manual login option
                    Button(action: {
                        viewModel.usePasswordLogin()
                    }) {
                        Text("Use Password Instead")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .underline()
                    }
                    
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                            .scaleEffect(0.8)
                    }
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Auto-trigger Face ID on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.authenticateWithBiometric()
            }
        }
        .onChange(of: viewModel.isUnlocked) { _, unlocked in
            if unlocked {
                withAnimation(.easeOut(duration: 0.3)) {
                    isUnlocked = true
                }
                
                // Post notification to proceed with app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: Notification.Name("BiometricUnlockCompleted"), object: nil)
                }
            }
        }
        .onChange(of: viewModel.shouldLogout) { _, shouldLogout in
            if shouldLogout {
                // Post logout notification
                NotificationCenter.default.post(name: .didLogoutUser, object: nil)
            }
        }
    }
}

class BiometricLockViewModel: ObservableObject {
    @Published var isAuthenticating = false
    @Published var errorMessage = ""
    @Published var isUnlocked = false
    @Published var shouldLogout = false
    
    var biometricType: String {
        BiometricAuthService.shared.biometricType
    }
    
    func authenticateWithBiometric() {
        guard !isAuthenticating else { return }
        
        #if DEBUG
        print("[BiometricLock] 🔐 Starting biometric authentication...")
        #endif
        
        isAuthenticating = true
        errorMessage = ""
        
        Task {
            do {
                // Try to authenticate with biometric
                _ = try await BiometricAuthService.shared.authenticateWithBiometric(
                    reason: "Authenticate to access KSR Cranes"
                )
                
                #if DEBUG
                print("[BiometricLock] ✅ Biometric authentication successful")
                #endif
                
                await MainActor.run {
                    self.isAuthenticating = false
                    self.isUnlocked = true
                }
                
            } catch let error as BiometricError {
                await MainActor.run {
                    self.isAuthenticating = false
                    self.handleBiometricError(error)
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticating = false
                    self.errorMessage = "An unexpected error occurred"
                }
            }
        }
    }
    
    private func handleBiometricError(_ error: BiometricError) {
        #if DEBUG
        print("[BiometricLock] ❌ Biometric error: \(error.localizedDescription)")
        #endif
        
        switch error {
        case .userCancelled:
            // User cancelled, don't show error
            errorMessage = ""
        case .noStoredCredentials:
            // No stored credentials, logout
            errorMessage = "No stored credentials found. Please login again."
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.shouldLogout = true
            }
        case .lockout:
            errorMessage = "Biometric authentication is locked. Please use your password."
        default:
            errorMessage = error.localizedDescription
        }
    }
    
    func usePasswordLogin() {
        #if DEBUG
        print("[BiometricLock] 🔑 User chose to use password login")
        #endif
        
        // Clear biometric credentials and logout
        BiometricAuthService.shared.removeStoredCredentials()
        shouldLogout = true
    }
}

struct BiometricLockView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricLockView()
    }
}