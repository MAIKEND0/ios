//
//  SplashLoginContainerView.swift
//  KSR Cranes App
//

import SwiftUI

struct SplashLoginContainerView: View {
    @State private var showLogin = false
    @State private var splashPhase: SplashPhase = .initial
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -45
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var copyrightOpacity: Double = 0
    @State private var backgroundOpacity: Double = 1
    
    enum SplashPhase {
        case initial, logoAnimation, titleAnimation, complete, fadeOut
    }

    var body: some View {
        ZStack {
            // MARK: - Background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.ksrDarkGray,
                    Color.ksrDarkGray.opacity(0.8),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            // MARK: - Splash Content
            if !showLogin {
                splashContent
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
            
            // MARK: - Login View
            if showLogin {
                LoginView()
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.easeIn(duration: 0.4)),
                        removal: .opacity.animation(.easeOut(duration: 0.2))
                    ))
            }
        }
        .onAppear {
            startSplashSequence()
        }
    }
    
    // MARK: - Splash Content
    private var splashContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // MARK: - Main Logo Section
            VStack(spacing: 24) {
                // Logo with enhanced animations
                Image("KSRLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .shadow(
                        color: .ksrYellow.opacity(0.3),
                        radius: logoScale > 0.8 ? 20 : 0,
                        x: 0,
                        y: logoScale > 0.8 ? 8 : 0
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .rotationEffect(.degrees(logoRotation))
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: logoScale)
                    .animation(.easeOut(duration: 1.2), value: logoRotation)
                    .animation(.easeInOut(duration: 0.6), value: logoOpacity)
                
                // Company Name with staggered animation
                VStack(spacing: 8) {
                    Text("KSR CRANES")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: titleOffset)
                        .animation(.easeInOut(duration: 0.5), value: titleOpacity)
                    
                    Text("Kranfører Udlejning")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(titleOpacity * 0.8)
                        .offset(y: titleOffset * 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: titleOffset)
                }
            }
            
            Spacer()
            
            // MARK: - Copyright with fade-in
            VStack(spacing: 4) {
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .opacity(copyrightOpacity)
                
                Text("© 2025 KSR Cranes")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(copyrightOpacity)
            }
            .padding(.bottom, 40)
            .animation(.easeInOut(duration: 0.5).delay(1.0), value: copyrightOpacity)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Animation Sequence
    private func startSplashSequence() {
        // Phase 1: Logo appears and scales up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            splashPhase = .logoAnimation
            withAnimation(.easeOut(duration: 0.8)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.2)) {
                logoRotation = 0
            }
        }
        
        // Phase 2: Title slides in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            splashPhase = .titleAnimation
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        // Phase 3: Copyright appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                copyrightOpacity = 1.0
            }
        }
        
        // Phase 4: Complete and prepare for transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            splashPhase = .complete
        }
        
        // Phase 5: Fade out and show login
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            splashPhase = .fadeOut
            withAnimation(.easeInOut(duration: 0.6)) {
                backgroundOpacity = 0.3
            }
            
            // Slight delay before showing login for smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showLogin = true
            }
        }
    }
}

// MARK: - Previews
struct SplashLoginContainerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashLoginContainerView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            SplashLoginContainerView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}
