//
//  SplashScreenView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 13/05/2025.
//

import SwiftUI
import Combine

struct SplashScreenView: View {
    @State private var currentPhase: SplashPhase = .initial
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var yOffset: CGFloat = 30
    
    // Enhanced animation states
    @State private var glowOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = 20
    @State private var loadingOpacity = 0.0
    @State private var copyrightOpacity = 0.0
    @State private var backgroundScale: CGFloat = 1.0
    
    // Loading states
    @State private var userRole = ""
    @State private var isLoggedIn = false
    @State private var loadingText = "Initializing..."
    @State private var loadingProgress: Double = 0.0
    @State private var showProgress = false
    @State private var dataPreloadComplete = false
    
    // Animation trigger for particles
    @State private var animationTrigger = false
    
    enum SplashPhase {
        case initial
        case logoAnimation
        case dataLoading
        case readyToTransition
        case showingApp
    }
    
    var body: some View {
        ZStack {
            switch currentPhase {
            case .initial, .logoAnimation, .dataLoading, .readyToTransition:
                // Show splash until we're completely ready
                splashContent
                    .transition(.identity)
                
            case .showingApp:
                // Only show final app when everything is ready
                destinationView
                    .transition(.opacity.animation(.easeIn(duration: 0.4)))
            }
        }
        .onAppear {
            #if DEBUG
            print("[SplashScreenView] 🚀 SplashScreenView appeared, starting sequence...")
            #endif
            startSplashSequence()
        }
        .animation(.easeInOut(duration: 0.3), value: currentPhase)
    }
    
    // MARK: - Destination View
    @ViewBuilder
    private var destinationView: some View {
        if isLoggedIn {
            RoleBasedRootView(userRole: userRole)
                .onAppear {
                    #if DEBUG
                    print("[SplashScreenView] 🔄 Showing RoleBasedRootView for role: \(userRole)")
                    #endif
                }
        } else {
            LoginView()
                .onAppear {
                    #if DEBUG
                    print("[SplashScreenView] 🔄 Showing LoginView")
                    #endif
                }
        }
    }
    
    // MARK: - Splash Content
    private var splashContent: some View {
        ZStack {
            // Enhanced gradient background with animation
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray.opacity(0.8),
                    Color.ksrDarkGray,
                    Color.black.opacity(0.9)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .scaleEffect(backgroundScale)
            .ignoresSafeArea()
            .overlay(
                // Animated particles for visual interest
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(Color.ksrYellow.opacity(0.1))
                        .frame(width: CGFloat.random(in: 2...5))
                        .position(
                            x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                            y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
                        )
                        .opacity(animationTrigger ? 0.8 : 0.0)
                        .scaleEffect(animationTrigger ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.5...3.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: animationTrigger
                        )
                }
            )
            
            VStack(spacing: 0) {
                Spacer()
                
                // MARK: - Logo Section with Enhanced Effects
                VStack(spacing: 24) {
                    ZStack {
                        // Glow effect
                        Image("KSRLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 170, height: 170)
                            .blur(radius: 15)
                            .opacity(glowOpacity * 0.4)
                            .foregroundColor(.ksrYellow)
                        
                        // Main logo with enhanced shadows
                        Image("KSRLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .shadow(
                                color: .ksrYellow.opacity(0.3),
                                radius: opacity > 0.8 ? 15 : 5,
                                x: 0,
                                y: opacity > 0.8 ? 8 : 3
                            )
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                            .scaleEffect(size)
                            .opacity(opacity)
                            .rotationEffect(.degrees(rotation))
                            .offset(y: yOffset)
                    }
                    
                    // Company branding with staggered animation
                    VStack(spacing: 12) {
                        Text("KSR CRANES")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(titleOpacity)
                            .offset(y: titleOffset)
                            .scaleEffect(titleOpacity)
                        
                        Text("Kranfører Udlejning")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(titleOpacity * 0.8)
                            .offset(y: titleOffset * 0.5)
                        
                        // Animated underline
                        if titleOpacity > 0.5 {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.ksrYellow.opacity(0.3),
                                            Color.ksrYellow,
                                            Color.ksrYellow.opacity(0.3)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: titleOpacity * 180, height: 2)
                                .opacity(titleOpacity)
                                .animation(.easeInOut(duration: 0.8), value: titleOpacity)
                        }
                    }
                }
                
                Spacer()
                
                // MARK: - Loading Section
                VStack(spacing: 16) {
                    // Loading indicator with enhanced styling
                    HStack(spacing: 12) {
                        if showProgress {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .ksrYellow))
                                    .scaleEffect(0.9)
                                
                                // Progress bar for detailed loading
                                if loadingProgress > 0 {
                                    ProgressView(value: loadingProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .ksrYellow))
                                        .frame(width: 120)
                                        .opacity(loadingProgress > 0.1 ? 1.0 : 0.0)
                                        .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                                }
                            }
                        }
                        
                        Text(loadingText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .animation(.easeInOut(duration: 0.3), value: loadingText)
                    }
                    .opacity(loadingOpacity)
                }
                .padding(.bottom, 20)
                
                // MARK: - Copyright
                Text("© 2025 KSR Cranes")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(copyrightOpacity)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Animation Sequence with Enhanced Phasing
    private func startSplashSequence() {
        #if DEBUG
        print("[SplashScreenView] 🎬 Starting splash sequence...")
        #endif
        
        // Start background particles
        animationTrigger = true
        
        // Phase 1: Logo entrance (0.1 - 1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            currentPhase = .logoAnimation
            
            withAnimation(.easeOut(duration: 0.9)) {
                self.size = 1.0
                self.opacity = 1.0
                self.yOffset = 0
            }
            
            withAnimation(.easeInOut(duration: 1.2)) {
                self.rotation = 360
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                self.glowOpacity = 1.0
            }
        }
        
        // Phase 2: Title animation (0.5 - 1.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                self.titleOffset = 0
                self.titleOpacity = 1.0
            }
        }
        
        // Phase 3: Start loading phase (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            currentPhase = .dataLoading
            
            withAnimation(.easeInOut(duration: 0.4)) {
                self.loadingOpacity = 1.0
                self.showProgress = true
            }
            
            // Start actual data preloading
            self.startDataPreloading()
        }
        
        // Phase 4: Copyright (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.copyrightOpacity = 1.0
            }
        }
    }
    
    // MARK: - Data Preloading
    private func startDataPreloading() {
        #if DEBUG
        print("[SplashScreenView] 📊 Starting data preloading...")
        #endif
        
        let loadingSteps = [
            ("Checking authentication...", 0.2),
            ("Loading user data...", 0.4),
            ("Preparing workspace...", 0.6),
            ("Initializing interface...", 0.8),
            ("Ready!", 1.0)
        ]
        
        // Execute loading steps with proper timing
        for (index, (text, progress)) in loadingSteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.loadingText = text
                    self.loadingProgress = progress
                }
                
                #if DEBUG
                print("[SplashScreenView] 📋 Step \(index + 1): \(text)")
                #endif
                
                // Perform actual loading tasks
                switch index {
                case 0:
                    self.checkAuthentication()
                case 1:
                    self.preloadUserData()
                case 2:
                    self.prepareWorkspace()
                case 3:
                    self.initializeInterface()
                case 4:
                    // Final step - mark as ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.completeLoading()
                    }
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Loading Tasks
    private func checkAuthentication() {
        #if DEBUG
        print("[SplashScreenView] 🔐 Checking authentication...")
        #endif
        
        // Check if user is logged in and get role
        isLoggedIn = AuthService.shared.isLoggedIn
        
        if isLoggedIn {
            userRole = AuthService.shared.getEmployeeRole() ?? ""
            
            #if DEBUG
            print("[SplashScreenView] ✅ User is logged in with role: \(userRole)")
            #endif
        } else {
            #if DEBUG
            print("[SplashScreenView] ❌ User not logged in")
            #endif
        }
    }
    
    private func preloadUserData() {
        if isLoggedIn {
            // Preload any necessary user data
            // This could include user preferences, cached data, etc.
            
            #if DEBUG
            print("[SplashScreenView] 📊 Preloading user data for: \(AuthService.shared.getEmployeeName() ?? "Unknown")")
            #endif
        } else {
            #if DEBUG
            print("[SplashScreenView] ℹ️ Skipping user data preload - not logged in")
            #endif
        }
    }
    
    private func prepareWorkspace() {
        // Initialize any workspace-specific data
        // This could include loading cached jobs, settings, etc.
        
        #if DEBUG
        print("[SplashScreenView] 🛠️ Preparing workspace for role: \(userRole.isEmpty ? "none" : userRole)")
        #endif
    }
    
    private func initializeInterface() {
        // Final interface preparations
        // This ensures everything is ready before showing the main app
        
        #if DEBUG
        print("[SplashScreenView] 🎨 Interface initialization complete")
        #endif
    }
    
    private func completeLoading() {
        // Mark data as preloaded and ready
        dataPreloadComplete = true
        
        #if DEBUG
        print("[SplashScreenView] ✅ Data preloading complete")
        print("[SplashScreenView] 🔄 Final state - isLoggedIn: \(isLoggedIn), userRole: '\(userRole)'")
        print("[SplashScreenView] 🚀 Transitioning to final app...")
        #endif
        
        // Short delay for smooth visual transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentPhase = .readyToTransition
            
            // Very short transition phase, then show final app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentPhase = .showingApp
                
                #if DEBUG
                print("[SplashScreenView] 🎯 Final transition complete - showing main app")
                #endif
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashScreenView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            SplashScreenView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}
